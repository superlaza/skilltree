from neo4django.db import models

class Course(models.NodeModel):
    name = models.StringProperty()
    prereqs = models.Relationship('Course', rel_type='REQUIRES')

