# Oloi OS Data Protection Architecture

## Governing rule

Oloi OS must never depend on one application, one laptop, one cloud provider, or one person for recovery.

## 1. Structured operational data

Use a managed PostgreSQL database (Supabase) for structured records and relationships:

- destinations, parks, reserves and conservancies
- accommodation records and room types
- suppliers, activities and travel times
- clients, enquiries, itineraries and quotes
- references to source documents

Do not store Excel workbooks, brochures, photographs, videos or signed documents inside database rows.

## 2. Original documents and large files

Google Drive remains the document system of record for existing client masters and source files. The database stores only:

- Drive file ID
- Drive folder ID
- document category
- source filename
- checksum where available
- imported_at and imported_by
- related database record ID

Original files are never deleted after import merely because their data has been structured.

## 3. Backups

Maintain three recoverable copies:

1. Live Supabase/PostgreSQL database.
2. Automated Supabase platform backup on a paid production plan.
3. Independent logical database export stored outside Supabase.

Database backups do not protect deleted Storage objects. Any Supabase Storage buckets require a separate object backup process. Google Drive files also require an independent export or secondary cloud copy.

## 4. Environments

- Production: real Oloi Shorua data; restricted administrator access.
- Staging: schema and synthetic/test data only.
- Local development: synthetic/test data only.

Production client data must never be copied into public GitHub branches, Lovable prompts, screenshots, sample seed files or developer laptops without a defined business need.

## 5. Access control

- Require individual user accounts; no shared logins.
- Require MFA for GitHub, Supabase and Google accounts.
- Browser applications use only the publishable/anon key.
- The Supabase service-role key is server-only and must never be committed to GitHub or placed in frontend code.
- Every exposed table must have Row Level Security enabled before data is inserted.
- Default access is deny; policies are added only for an identified role and purpose.
- Founder/admin, operations and read-only roles must be separated.

## 6. Schema change control

All database changes must be written as versioned migrations in `supabase/migrations/` and reviewed before production deployment. The production database must not be changed ad hoc through Lovable or the Supabase dashboard.

## 7. Import safety

Every import must:

- preserve the original source file
- create an import batch record
- validate required fields before committing
- reject or quarantine ambiguous rows
- record row-level errors
- be repeatable without creating duplicates
- support rollback by import batch

## 8. Immediate controls

Before uploading business data:

- make the GitHub repository private
- enable branch protection on `main`
- configure MFA
- create a paid production Supabase project in the chosen region
- apply migrations through the CLI or CI only
- enable daily backups
- create an off-site logical backup schedule
- keep Google Drive as the current source of truth until each import is verified
