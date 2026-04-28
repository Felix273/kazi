from django.db import migrations

SKILLS = [
    # Manual Labour
    ('House Cleaning', 'manual', 'cleaning'),
    ('Moving & Packing', 'manual', 'moving'),
    ('Painting', 'manual', 'paint'),
    ('Gardening & Landscaping', 'manual', 'garden'),
    ('Laundry & Ironing', 'manual', 'laundry'),
    ('Car Washing', 'manual', 'car'),
    ('Construction & Masonry', 'manual', 'construction'),
    ('Fumigation & Pest Control', 'manual', 'pest'),

    # Professional Services
    ('Plumbing', 'professional', 'plumbing'),
    ('Electrical Work', 'professional', 'electrical'),
    ('Carpentry & Furniture', 'professional', 'carpenter'),
    ('Appliance Repair', 'professional', 'repair'),
    ('AC Installation & Repair', 'professional', 'ac'),
    ('Security Systems', 'professional', 'security'),
    ('Catering & Cooking', 'professional', 'chef'),
    ('Tutoring & Teaching', 'professional', 'tutor'),
    ('Driving & Chauffeur', 'professional', 'driving'),
    ('Tailoring & Alterations', 'professional', 'sewing'),
    ('Photography', 'professional', 'camera'),
    ('Beauty & Hair', 'professional', 'beauty'),

    # Errands & Delivery
    ('Grocery Shopping', 'errands', 'shopping'),
    ('Document Delivery', 'errands', 'delivery'),
    ('Airport Pickup/Drop', 'errands', 'airport'),
    ('Parcel Collection', 'errands', 'parcel'),
    ('Queue Management', 'errands', 'queue'),
    ('Bill Payments', 'errands', 'bill'),

    # Digital Work
    ('Data Entry', 'digital', 'data'),
    ('Graphic Design', 'digital', 'design'),
    ('Social Media Management', 'digital', 'social'),
    ('Virtual Assistant', 'digital', 'va'),
    ('Transcription', 'digital', 'transcript'),
    ('Translation (Swahili/English)', 'digital', 'translate'),
    ('Video Editing', 'digital', 'video'),
    ('Web Research', 'digital', 'research'),
]


def seed_skills(apps, schema_editor):
    Skill = apps.get_model('users', 'Skill')
    for name, category, icon in SKILLS:
        Skill.objects.get_or_create(name=name, defaults={'category': category, 'icon': icon})


def reverse_skills(apps, schema_editor):
    Skill = apps.get_model('users', 'Skill')
    Skill.objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [
        ('users', '0001_initial'),
    ]
    operations = [
        migrations.RunPython(seed_skills, reverse_skills),
    ]
