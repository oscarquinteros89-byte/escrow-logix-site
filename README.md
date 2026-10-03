# Escrow Logix · Open Escrow (test site)

A test copy of the Escrow Logix open-escrow intake page (prototype V0.3), hosted on GitHub Pages so it can be tried on desktop and phone.

**Live test link:** https://oscarquinteros89-byte.github.io/escrow-logix-site/

## What to try

- **The intake flow:** choose Purchase or Refinance, fill in the steps, and submit. In prototype mode nothing is sent or stored; the confirmation screen shows the record that would go to the CRM.
- **Rep links:** add a rep's name to the address, e.g. `/escrow-logix-site/AndreaKawawaki` or `?rep=andrea-kawawaki`. The rep's name (and photo, if listed) appears on the form and travels with the request.
- **Tracking tags:** `?utm_source=flyer&utm_campaign=fall` is captured with the request.

## Files

- `index.html`: the whole site in one file. Everything that changes for production is in the `CONFIG` block at the top of the script: CRM webhook, ShareFile upload links, rep directory, and the base path.
- `404.html`: makes rep links like `/AndreaKawawaki` work on GitHub Pages by forwarding them to `?rep=AndreaKawawaki`.

## Notes

- Brand images (logo, photos, team) load live from escrowlogix.com.
- The page tells search engines not to list it. Remove the `robots` meta tag at launch.
- Sensitive documents never go through this page or the CRM. They go straight to ShareFile once its upload form is connected.
