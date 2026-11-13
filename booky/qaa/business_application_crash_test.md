you# Business application crash-test checklist

Use this checklist when resuming the business signup and notification work.
These are manual test steps; they have not been run yet.

## Before testing

- [ ] Apply `supabase/migrations/20261018000100_business_registration_requests.sql` in Supabase SQL Editor. This creates the application table and signup trigger.
- [ ] Apply `supabase/migrations/20261018000200_business_application_notifications.sql` after the first migration. This adds status notifications and backfills the current status of applications already in the table.
- [ ] Apply `supabase/migrations/20261018000300_profile_avatars.sql` to create the avatar storage bucket and per-user upload policies.
- [ ] Apply `supabase/migrations/20261018000400_venue_photo_storage.sql` to create the venue image bucket and owner-only write policies.
- [ ] Apply `supabase/migrations/20261018000500_business_application_category.sql`. This adds a filterable category to each application and stores the signup selection.
- [ ] Confirm the existing `public.notifications` table and notification policies are installed.
- [ ] Use test email accounts so signup and status changes do not affect real applicants.

## Customer signup regression

- [ ] From the auth screen, use the normal customer signup route.
- [ ] Confirm the account is created in Supabase Auth and `public.profiles` as before.
- [ ] Confirm no row is added to `public.business_registration_requests` for that customer.

## Business application: pending

- [ ] From the initial auth screen, tap **Own or manage a business? Apply here**.
- [ ] Submit a name, business name, category, email, and password.
- [ ] Confirm the Auth user and profile are created.
- [ ] Confirm one `business_registration_requests` row exists with that user's UUID, business name, selected category, and `status = pending`.
- [ ] If email confirmation is enabled, confirm the app says the application was submitted and asks the user to confirm their email.
- [ ] Sign in as that user and open Notifications. Confirm the **Welcome!** notice and **Pending review** status appear, with an unread dot.
- [ ] Tap the notice and confirm it becomes read.

## Rejection

- [ ] In Supabase, change the test request's `status` from `pending` to `rejected`.
- [ ] Open or refresh Notifications as that user.
- [ ] Confirm the rejection notice appears with **Rejected** status and the contact-us message.

## Approval and tutorial

- [ ] Change another test request's `status` from `pending` to `approved`.
- [ ] Confirm the user receives **Welcome aboard, boss!** with **Approved** status.
- [ ] Tap the approval notice and confirm the short dashboard/schedule/services/bookings guide opens.
- [ ] Assign that user's UUID to the correct venue's `owner_id`.
- [ ] Sign out and sign in again; confirm the app routes the linked user to the business dashboard.
- [ ] As a negative check, approve a request without linking `venues.owner_id`; confirm approval alone does not grant manager dashboard access.

## Access and repeat checks

- [ ] Confirm one user's app session can only read that user's own application row.
- [ ] Confirm the app client cannot change the request status; status changes are made by you in Supabase.
- [ ] Confirm each status transition adds one notification and the existing notification bell's unread indicator updates after refresh/reopen.
- [ ] Confirm running the notification migration again does not duplicate the backfilled notification for an existing request.

## Profile details and picture

- [ ] Sign in, open Profile, and tap **Details** on the account card.
- [ ] Confirm the edit screen shows the account name, read-only email, profile phone number, and current picture if one is set.
- [ ] Change the name and profile phone, save, then return to Profile and confirm the updated name appears.
- [ ] Choose a photo under 5 MB, save, and confirm it appears in both Profile and Edit Profile.
- [ ] Close and reopen the app, then confirm the name, phone, and picture persist.
- [ ] Confirm editing the profile phone does not change the account's email sign-in method.

## Venue cover and gallery photos

- [ ] Sign in with a venue manager account and open Settings → **Venue Photos**.
- [ ] Change the cover photo; confirm it updates on Home, Search, and the venue details page.
- [ ] Add a gallery photo; open the venue details page as a customer and confirm it appears under Photos.
- [ ] Tap a gallery photo to view it larger, then remove it from the manager screen and confirm it disappears for customers.
- [ ] Try adding an image larger than 5 MB and confirm the app rejects it with a helpful message.
- [ ] Confirm a manager cannot upload or change photos for a different venue.
