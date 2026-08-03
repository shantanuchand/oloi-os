# Oloi OS

AI-powered operating system for Oloi Shorua.

Oloi OS is being built as a learning journey operating system: knowledge, traveller relationships, journey design, supplier intelligence and operational memory in one connected platform.

## Current build

Phase 1 establishes the Supabase foundation:

- Knowledge graph with provenance, confidence and version history
- Traveller profiles, households, preferences, constraints and interactions
- Journey lifecycle, day rhythm, components and explainable design decisions
- Supplier records, products, rates and evidence-backed assessments
- Workspace tenancy and row-level security
- Local seed data and database smoke tests

## Repository structure

```text
docs/architecture/        System boundaries and design decisions
supabase/migrations/      Ordered PostgreSQL/Supabase migrations
supabase/tests/           pgTAP database tests
supabase/seed.sql         Local development records
```

## Local development

Requirements:

- Docker
- Supabase CLI

Start a clean local database:

```bash
supabase start
supabase db reset
```

Run database tests:

```bash
supabase test db
```

## Architectural boundary

The Oloi Shorua Framework is the governing philosophy. The Oloi OS Constitution translates relevant principles into business rules. This repository contains the software implementation and does not duplicate the philosophical text.

## Next build targets

1. Typed application client and generated database types
2. Traveller discovery workflow
3. Accommodation and destination importers
4. Journey design API
5. Travel-time and routing intelligence
6. Knowledge ingestion and retrieval
