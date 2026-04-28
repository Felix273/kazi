from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from django.contrib.auth import get_user_model
from apps.jobs.models import Job
import logging

logger = logging.getLogger(__name__)

User = get_user_model()


class JobMatchingService:
    """
    Core matching engine — finds nearby available workers for a job.
    Uses PostGIS spatial queries for efficient geo-matching.
    """

    def find_workers_for_job(self, job: Job) -> list:
        """
        Find available workers near the job location.
        Returns ordered list of workers (closest first, then by rating).
        """
        job_location = job.location

        # Base query: active workers within radius who are online
        workers = User.objects.filter(
            user_type__in=['worker', 'both'],
            is_active=True,
            is_online=True,
            location__isnull=False,
            location__dwithin=(job_location, D(km=job.search_radius_km))
        ).annotate(
            distance=Distance('location', job_location)
        )

        # Filter by required skills if specified
        if job.required_skills.exists():
            skill_ids = job.required_skills.values_list('id', flat=True)
            workers = workers.filter(
                worker_profile__skills__id__in=skill_ids
            ).distinct()

        # Exclude employer themselves
        workers = workers.exclude(id=job.employer.id)

        # Order: distance first, then rating
        workers = workers.order_by('distance', '-average_rating')

        # Cap at 50 workers per broadcast
        return list(workers[:50])

    def expand_search(self, job: Job, multiplier: float = 1.5) -> list:
        """
        Called if initial match finds too few workers.
        Expands the search radius and retries.
        """
        expanded_radius = job.search_radius_km * multiplier
        logger.info(f"Expanding search for job {job.id} to {expanded_radius}km")

        job_location = job.location
        workers = User.objects.filter(
            user_type__in=['worker', 'both'],
            is_active=True,
            location__isnull=False,
            location__dwithin=(job_location, D(km=expanded_radius))
        ).annotate(
            distance=Distance('location', job_location)
        ).exclude(id=job.employer.id).order_by('distance', '-average_rating')

        return list(workers[:50])
