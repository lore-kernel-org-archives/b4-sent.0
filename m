From: Alban Kurti <kurti@invicto.ai>
Subject: [PATCH v4 0/2] rust: samples: add missing newlines to printing
 calls
Date: Sun, 04 May 2025 17:41:13 +0200
Message-Id: <20250504-pr_info-newline-fix-v4-0-53467c401eb6@invicto.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJmKF2gC/x2MQQqAMAzAviI9W5hju/gVEdlmpwWpsoEK4t8tH
 hNIHqhUmCr0zQOFTq68i4JrG0hrkIWQZ2WwxnrjjcOjTCx5R6FrYyHMfCNF3+VgjY8hgZZHIdX
 /dRjf9wOdsi4mZQAAAA==
X-Change-ID: 20250504-pr_info-newline-fix-eb51fa205bac
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Vincenzo Palazzo <vincenzopalazzodev@gmail.com>, 
 Xiangfei Ding <dingxiangfei2009@gmail.com>
Cc: Fiona Behrens <me@kloenk.dev>, Alban Kurti <kurti@invicto.ai>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746373294; l=1007;
 i=kurti@invicto.ai; s=20250504; h=from:subject:message-id;
 bh=vvngYuf/ckQdGCMZX1hN44ueg1Iy36aEVBTa5YONnsA=;
 b=Va9mPD+1N1ACX78IuRwJoM0OwWAKEGDVLBUw753hij1yoByanyBs8J5m/Y0G9SGU8+kp/RTMA
 GucJ1PPsn+YCYZa7OFFk8RlOQeySbmyZaGxwS7yzHAECsPSDcGZkXzS
X-Developer-Key: i=kurti@invicto.ai; a=ed25519;
 pk=7724GF1zrN6rA3Z2xkyAmVGkoOQxv7bMUvXB4IsIPUs=
X-Endpoint-Received: by B4 Relay for kurti@invicto.ai/20250504 with auth_id=398
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adding newline at the end of all Rust pr_* and dev_* macro
calls that miss a newline.
`pr_*!` and `dev_*!` macros are supposed to be called
with a newline at the end, just like in the C side
such that independent lines are not visually missed.
There were no dev_*! cases with a missing newline found.

Signed-off-by: Alban Kurti <kurti@invicto.ai>
---
Changes in v4:
- Split into two patches the 6th patch from v3 addressing separate fixes
- Link to v3: https://lore.kernel.org/rust-for-linux/20250206-printing_fix-v3-0-a85273b501ae@invicto.ai/

---
Alban Kurti (2):
      rust: samples: add missing newline to pr_info! calls in rust_print_main
      rust: samples: add missing newline to pr_info! calls in rust_print_main

 samples/rust/rust_print_main.rs | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)
---
base-commit: b4432656b36e5cc1d50a1f2dc15357543add530e
change-id: 20250504-pr_info-newline-fix-eb51fa205bac

Best regards,
-- 
Alban Kurti <kurti@invicto.ai>

