from rest_framework.views import APIView
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.gis.geos import Point
from django.utils import timezone
from django.db import transaction

from apps.jobs.models import Job, JobApplication, Review
from apps.jobs.serializers import (
    JobSerializer, JobCreateSerializer,
    JobApplicationSerializer, ReviewSerializer
)
from apps.jobs.services.matching_service import JobMatchingService
from apps.payments.models import Payment
from apps.payments.services.intasend_service import IntaSendService
from apps.chat.models import ChatRoom
from apps.notifications.services import NotificationService


class JobListView(ListAPIView):
    serializer_class = JobSerializer

    def get_queryset(self):
        qs = Job.objects.filter(status='open').select_related('employer').prefetch_related('required_skills')
        category = self.request.query_params.get('category')
        if category and category != 'all':
            qs = qs.filter(category=category)
        return qs


class JobCreateView(APIView):
    def post(self, request):
        serializer = JobCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data

        with transaction.atomic():
            job = Job.objects.create(
                employer=request.user,
                title=data['title'],
                description=data['description'],
                category=data['category'],
                budget=data['budget'],
                is_negotiable=data.get('is_negotiable', False),
                duration_value=data['duration_value'],
                duration_unit=data['duration_unit'],
                location=Point(data['longitude'], data['latitude'], srid=4326),
                location_address=data['location_address'],
                search_radius_km=data.get('search_radius_km', 10),
            )

            if 'required_skill_ids' in data:
                job.required_skills.set(data['required_skill_ids'])

        # Find and notify nearby workers asynchronously
        self._broadcast_to_workers(job)

        return Response(JobSerializer(job).data, status=status.HTTP_201_CREATED)

    def _broadcast_to_workers(self, job):
        try:
            matcher = JobMatchingService()
            workers = matcher.find_workers_for_job(job)

            if len(workers) < 3:
                workers = matcher.expand_search(job)

            notif_service = NotificationService()
            for worker in workers:
                notif_service.notify_new_job(worker, job)

            job.notified_workers_count = len(workers)
            job.save(update_fields=['notified_workers_count'])
        except Exception as e:
            import logging
            logging.getLogger(__name__).error(f"Worker broadcast failed for job {job.id}: {e}")


class JobDetailView(RetrieveAPIView):
    serializer_class = JobSerializer
    queryset = Job.objects.all()
    lookup_field = 'pk'


class ApplyForJobView(APIView):
    def post(self, request, pk):
        try:
            job = Job.objects.get(pk=pk, status='open')
        except Job.DoesNotExist:
            return Response({'detail': 'Job not found or no longer available.'},
                            status=status.HTTP_404_NOT_FOUND)

        if job.employer == request.user:
            return Response({'detail': 'You cannot apply to your own job.'},
                            status=status.HTTP_400_BAD_REQUEST)

        if JobApplication.objects.filter(job=job, worker=request.user).exists():
            return Response({'detail': 'You have already applied to this job.'},
                            status=status.HTTP_400_BAD_REQUEST)

        application = JobApplication.objects.create(
            job=job,
            worker=request.user,
            cover_note=request.data.get('cover_note', ''),
            proposed_rate=request.data.get('proposed_rate'),
        )

        NotificationService().notify_application_received(job.employer, job, request.user)

        return Response(JobApplicationSerializer(application).data,
                        status=status.HTTP_201_CREATED)


class JobApplicationsView(APIView):
    def get(self, request, pk):
        try:
            job = Job.objects.get(pk=pk, employer=request.user)
        except Job.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        applications = job.applications.select_related('worker').order_by('-created_at')
        return Response(JobApplicationSerializer(applications, many=True).data)


class AcceptApplicationView(APIView):
    def post(self, request, pk, application_id):
        try:
            job = Job.objects.get(pk=pk, employer=request.user, status='open')
            application = JobApplication.objects.get(id=application_id, job=job)
        except (Job.DoesNotExist, JobApplication.DoesNotExist):
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        with transaction.atomic():
            # Assign worker
            job.assigned_worker = application.worker
            job.status = Job.Status.ASSIGNED
            job.save(update_fields=['assigned_worker', 'status'])

            # Accept this application
            application.status = JobApplication.Status.ACCEPTED
            application.save(update_fields=['status'])

            # Decline all others
            JobApplication.objects.filter(job=job).exclude(
                id=application_id
            ).update(status=JobApplication.Status.DECLINED)

            # Create chat room
            ChatRoom.objects.create(
                job=job,
                employer=request.user,
                worker=application.worker,
            )

            # Create pending payment record
            payment = Payment(
                job=job,
                employer=request.user,
                worker=application.worker,
                amount=job.budget,
                payer_phone=request.user.phone_number,
            )
            payment.calculate_fees()
            payment.save()

        NotificationService().notify_application_accepted(application.worker, job)

        return Response({'detail': 'Worker assigned. Chat room created.',
                         'chat_room_id': str(job.chat_room.id)})


class CompleteJobView(APIView):
    """Employer confirms job is done — triggers payment release"""
    def post(self, request, pk):
        try:
            job = Job.objects.get(pk=pk, employer=request.user,
                                  status__in=['assigned', 'in_progress'])
        except Job.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        with transaction.atomic():
            job.status = Job.Status.COMPLETED
            job.completed_at = timezone.now()
            job.save(update_fields=['status', 'completed_at'])

            # Release escrow
            try:
                payment = job.payment
                if payment.status == Payment.Status.HELD:
                    IntaSendService().release_to_worker(payment)
                    NotificationService().notify_payment_released(payment)
            except Payment.DoesNotExist:
                pass

            # Update worker stats
            worker = job.assigned_worker
            worker.total_jobs_completed += 1
            worker.save(update_fields=['total_jobs_completed'])

        return Response({'detail': 'Job marked complete. Payment released.'})


class InitiatePaymentView(APIView):
    """Employer triggers M-Pesa STK push after accepting a worker"""
    def post(self, request):
        job_id = request.data.get('job_id')
        payer_phone = request.data.get('payer_phone', request.user.phone_number)

        try:
            job = Job.objects.get(id=job_id, employer=request.user, status='assigned')
            payment = job.payment
        except (Job.DoesNotExist, Payment.DoesNotExist):
            return Response({'detail': 'Job or payment not found.'},
                            status=status.HTTP_404_NOT_FOUND)

        payment.payer_phone = payer_phone
        payment.save(update_fields=['payer_phone'])

        try:
            result = IntaSendService().initiate_stk_push(payment)
            return Response({'detail': 'STK push sent. Check your phone.', 'data': result})
        except Exception:
            return Response({'detail': 'Payment initiation failed. Try again.'},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE)


class SubmitReviewView(APIView):
    def post(self, request, pk):
        try:
            job = Job.objects.get(pk=pk, status='completed')
        except Job.DoesNotExist:
            return Response({'detail': 'Job not found or not completed.'},
                            status=status.HTTP_404_NOT_FOUND)

        # Determine reviewee
        if request.user == job.employer:
            reviewee = job.assigned_worker
        elif request.user == job.assigned_worker:
            reviewee = job.employer
        else:
            return Response({'detail': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        if Review.objects.filter(job=job, reviewer=request.user).exists():
            return Response({'detail': 'You have already reviewed this job.'},
                            status=status.HTTP_400_BAD_REQUEST)

        rating = request.data.get('rating')
        if not rating or not (1 <= int(rating) <= 5):
            return Response({'detail': 'Rating must be between 1 and 5.'},
                            status=status.HTTP_400_BAD_REQUEST)

        review = Review.objects.create(
            job=job, reviewer=request.user, reviewee=reviewee,
            rating=int(rating), comment=request.data.get('comment', ''),
        )

        # Update reviewee average rating
        all_reviews = Review.objects.filter(reviewee=reviewee)
        avg = sum(r.rating for r in all_reviews) / len(all_reviews)
        reviewee.average_rating = round(avg, 2)
        reviewee.total_reviews = len(all_reviews)
        reviewee.save(update_fields=['average_rating', 'total_reviews'])

        return Response(ReviewSerializer(review).data, status=status.HTTP_201_CREATED)


class WorkerApplicationsView(APIView):
    """List the logged-in worker's job applications"""
    def get(self, request):
        applications = JobApplication.objects.filter(
            worker=request.user
        ).select_related('job').order_by('-created_at')
        return Response(JobApplicationSerializer(applications, many=True).data)


class StartJobView(APIView):
    def post(self, request, pk):
        try:
            job = Job.objects.get(pk=pk, assigned_worker=request.user, status='assigned')
        except Job.DoesNotExist:
            return Response({'detail': 'Job not found or cannot be started.'}, status=status.HTTP_404_NOT_FOUND)

        job.status = Job.Status.IN_PROGRESS
        job.save(update_fields=['status'])
        NotificationService().notify_job_started(job.employer, job)
        return Response({'detail': 'Job started.'})


class CancelJobView(APIView):
    def post(self, request, pk):
        try:
            job = Job.objects.get(pk=pk)
        except Job.DoesNotExist:
            return Response({'detail': 'Job not found.'}, status=status.HTTP_404_NOT_FOUND)

        if request.user != job.employer and request.user != job.assigned_worker:
            return Response({'detail': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        if job.status not in ['open', 'assigned', 'in_progress']:
            return Response({'detail': 'Job cannot be cancelled.'}, status=status.HTTP_400_BAD_REQUEST)

        job.status = Job.Status.CANCELLED
        job.save(update_fields=['status'])
        NotificationService().notify_job_cancelled(job.employer, job)
        return Response({'detail': 'Job cancelled.'})


class DisputeJobView(APIView):
    def post(self, request, pk):
        try:
            job = Job.objects.get(pk=pk, status__in=['assigned', 'in_progress', 'completed'])
        except Job.DoesNotExist:
            return Response({'detail': 'Job not found.'}, status=status.HTTP_404_NOT_FOUND)

        if request.user != job.employer and request.user != job.assigned_worker:
            return Response({'detail': 'Not authorized.'}, status=status.HTTP_403_FORBIDDEN)

        job.status = Job.Status.DISPUTED
        job.dispute_reason = request.data.get('reason', '')
        job.save(update_fields=['status', 'dispute_reason'])
        NotificationService().notify_job_disputed(job.employer, job)
        return Response({'detail': 'Job marked as disputed.'})
