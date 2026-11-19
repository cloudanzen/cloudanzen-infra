# cloudanzen-staging and cloudanzen-prod were created in the console on
# 2026-11-19 before this root first ran. Import them instead of creating
# new projects. These blocks are no-ops once the projects are in state and
# can be removed afterwards.
import {
  to = google_project.env["staging"]
  id = "cloudanzen-staging"
}

import {
  to = google_project.env["prod"]
  id = "cloudanzen-prod"
}
