From: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
Subject: [PATCH 0/3] rust: workqueue: add safe cancellation and status
 methods
Date: Thu, 02 Apr 2026 08:53:45 +0530
Message-Id: <20260402-rust-next-v1-0-0940bb8f201c@multicorewareinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAELhzWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEwMj3aLS4hLdvNSKEl1Dy6REA+PExBTjNBMloPqCotS0zAqwWdGxtbU
 A6LXndVsAAAA=
To: rust-for-linux@vger.kernel.org
Cc: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775100227; l=2331;
 i=aakash.bollineni@multicorewareinc.com; s=20260402;
 h=from:subject:message-id; bh=doSMiViGmwMuDM5rPkB2CTHK7xNoHLVvMHS/OAdAWO0=;
 b=Vcosgj7HKX1yLZr5GDRW0Us3rYAn/WRoTqqGSMQkcqIzvXR3ZU0gp1TzurpL7BxgCEY4iqIKI
 mde0VvMo/sqCtzYrCh2JWyV96UDxXLfAZzsyqAIoE6Bk/HAqI61qtjD
X-Developer-Key: i=aakash.bollineni@multicorewareinc.com; a=ed25519;
 pk=r3Gonl+2k+8RozN9U/XwfICQdnRlAcLeeAfsExmurdE=
X-Endpoint-Received: by B4 Relay for aakash.bollineni@multicorewareinc.com/20260402 with auth_id=711
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series modernizes the Rust workqueue infrastructure by adding
methods for status checking and safe cancellation. These capabilities
are essential for implementing safe driver teardown paths, such as in
'Drop' implementations or device removal, where background tasks must
be stopped before resources are freed.
This version (v2) addresses the feedback from Miguel Ojeda:
- The work has been split into a logical 3-patch series.
- Spurious changes (top-level .kunitconfig) have been removed.
- Initialization for DelayedWork is now handled via a robust C-helper
  (INIT_DELAYED_WORK) to ensure correct timer function registration.
- Pointer arithmetic in the reclamation path has been simplified and
  verified to be underflow-free.
Summary of changes:
1. Helpers: Adds C FFI wrappers for workqueue macros and robust
   DelayedWork initialization.
2. Core API: Implements is_pending(), cancel(), and cancel_sync() with
   guaranteed pointer reclamation and layout safety (#[repr(transparent)]).
3. Tests: Adds a comprehensive KUnit suite and a standalone stress-test
   sample.
The implementation has been verified on x86_64 using KUnit (4/4 PASSED)
and confirmed to be race-free under high-load stress testing.
Changelog v1 -> v2:
- Split into a 3-patch series to separate helpers from API and tests.
- Replaced manual timer initialization with rust_helper_init_delayed_work.
- Fixed field offset arithmetic in container_of macro path.
- Expanded KUnit tests to cover DelayedWork specifically.
- Wrapped commit messages and cover letter to 75 columns.

Signed-off-by: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
---
Aakash Bollineni (3):
      rust: helpers: add workqueue helpers
      rust: workqueue: add safe cancellation and status methods
      rust: workqueue: add KUnit and sample stress tests

 rust/helpers/workqueue.c            |  34 +++
 rust/kernel/workqueue.rs            | 467 +++++++++++++++++++++++++++++++++---
 samples/rust/Makefile               |   2 +
 samples/rust/rust_workqueue_test.rs | 214 +++++++++++++++++
 4 files changed, 682 insertions(+), 35 deletions(-)
---
base-commit: bf074eb6891be799174ff42e0051492681fdc045
change-id: 20260402-rust-next-19ba03aad3f4

Best regards,
-- 
Aakash Bollineni <aakash.bollineni@multicorewareinc.com>

