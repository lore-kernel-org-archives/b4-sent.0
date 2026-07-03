From: Jahnavi MN <jahnavimn@google.com>
Subject: [PATCH 0/7] rust_binder : Implement dynamic debug logging mask
Date: Fri, 03 Jul 2026 15:29:21 +0000
Message-Id: <20260703-rust_binder_debug_mask-v1-0-9bdf12b5325c@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFHVR2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcwMj3aLS4pL4pMy8lNSi+JTUpNL0+NzE4mxdM2Mzc2NzA0NTMyMTJaD
 mgqLUtMwKsMHRsbW1AJF2f9hoAAAA
X-Change-ID: 20260702-rust_binder_debug_mask-636737015624
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>, Alice Ryhl <aliceryhl@google.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Jahnavi MN <jahnavimn@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783092563; l=4101;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=209Nac/iJ9paij4wD2LYPworVIG6Ys3P+mfxV+DyI3U=;
 b=MORHRCvDgYndUEdGZgXgwmaLFx7DWtaLBbhbEpXc09UDEQCTNg1U3MLVlzCs9O6OrPKN5pvGy
 Nf/juQn40K2CuQlBR5ncjlTRvbSdCIv0F7PfcrfJkkeVYcezeneLF7U
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Why we implemented this feature : 

While working with and testing the Rust implementation of the Binder 
driver (rust_binder), we realized that diagnosing transaction failures 
and protocol errors was extremely difficult. When a user-space application 
sends malformed data or makes a lifecycle mistake, the driver rejects it 
with a generic error code (like `-EINVAL`). Without internal logs, the 
driver acts as a "black box," forcing developers to guess which check 
failed.

In the legacy C Binder driver, this issue is solved using a dynamic 
`debug_mask` module parameter that toggles verbose logs for specific 
subsystems. This series brings the same critical capability to the Rust 
Binder driver to provide developers with clear, real-time feedback.

How this helps and simplifies debugging : 
Instead of rebuilds, reboots, or guessing:
- Developers can enable logs instantly on a running device by writing to 
  `/sys/module/rust_binder/parameters/debug_mask`.
- It prints the exact reason for failures (such as alignment errors, 
  mismatched call stacks, or invalid handle references) directly into 
  `dmesg`, reducing debugging time from hours to seconds.
- It protects system logs by keeping logging off by default and only 
  enabling it when developers are actively troubleshooting.

Code development approach : 
We built this system in a structured, progressive approach:
1. Infrastructure Bridging (C/Rust FFI) :
   Because the Rust `module!` macro cannot yet declare parameters, we 
   declared `debug_mask` in a C companion file and linked to it in Rust via 
   FFI. We used volatile memory reads to ensure changes to the mask are 
   detected instantly at runtime.
   
2. Verification Setup :
   We created a `binder_debug!` macro and instrumented process `open`, 
   `flush`, and `release` calls under the `BINDER_DEBUG_OPEN_CLOSE` mask. 
   These low-frequency events allowed us to verify the setup without log 
   flooding.
   
3. Targeted Instrumentation :
   We then systematically added detailed logs across 3 major categories:
   - User Error : Captures API misuse like misaligned FD arrays, 
     negative reference count transitions, and invalid death/freeze 
     notifications.
   - Failed Transaction : Dumps a complete diagnostics log on 
     transaction errors (IDs, PIDs, sizes, OOM states, and line numbers).
   - Dead Transaction : Logs in-flight cancellations, aborted 
     replies, and notification cleanups when processes exit prematurely.

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
Jahnavi MN (7):
      rust_binder: Add dynamic debug logging mask
      rust_binder: Implement the BINDER_DEBUG_USER_ERROR logging mask for freezer-related operation
      rust_binder: Implement the BINDER_DEBUG_USER_ERROR logging mask for reference counting and death notification operations
      rust_binder: Implement the BINDER_DEBUG_USER_ERROR logging mask for transaction parsing and protocol validation failures
      rust_binder: Implement the BINDER_DEBUG_FAILED_TRANSACTION logging mask for transaction parsing and routing failures
      rust_binder: Implement BINDER_DEBUG_FAILED_TRANSACTION logging for death notification allocation failures
      rust_binder: Implement the BINDER_DEBUG_DEAD_TRANSACTION logging mask to trace in-flight cancellations during teardown

 drivers/android/binder/debug.rs            |  49 ++++++++++
 drivers/android/binder/freeze.rs           |  57 ++++++++---
 drivers/android/binder/node.rs             |  24 ++++-
 drivers/android/binder/process.rs          |  71 +++++++++++---
 drivers/android/binder/rust_binder_main.rs |  11 ++-
 drivers/android/binder/rust_binderfs.c     |   3 +
 drivers/android/binder/thread.rs           | 147 +++++++++++++++++++++++++----
 drivers/android/binder/transaction.rs      |  16 +++-
 8 files changed, 328 insertions(+), 50 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260702-rust_binder_debug_mask-636737015624

Best regards,
-- 
Jahnavi MN <jahnavimn@google.com>

