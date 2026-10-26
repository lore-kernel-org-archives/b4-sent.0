From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH 0/2] nova-core: add initial support for gpu timer
Date: Mon, 26 Oct 2026 12:56:47 +1000
Message-Id: <20261026-drm-rust-next-v1-0-14a4ae469175@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7bkElIvpKdAhdaw9ZrBWC+Pekw
 xzmMFMgkTAlmFQBoZcTn7GJ6RS4fY0bIfvmYLUdTAO9HChPujFSvtGPxpEOPTkfoDWXUOD8/+a
 l1g9MHKSyXwAAAA==
X-Change-ID: 20261026-drm-rust-next-d81ce0f4ecdf
To: Andreas Hindborg <a.hindborg@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Lyude Paul <lyude@redhat.com>, 
 Gary Guo <gary@garyguo.net>, Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: rust-for-linux@vger.kernel.org, nova-gpu@lists.linux.dev, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1299; i=airlied@redhat.com;
 h=from:subject:message-id; bh=AWylCJ32K1PQVK694S3XIzNgSfSyKYezuYTSe8/2JZc=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq3sF5TvjdrYFXJqaTGnHQnKmCCgVOheitNaqBP
 AzzJerMwjaJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCat7BeQAKCRAMdPNZecSG
 vqWrD/47tGijWYutlf7++GxY1NwK2qakbkhgLW2ko9JQ6au7YmOEBSotDqv/NqR+U8HrfyHIZ+Q
 HkmzzUMUP5Ab+7ezICsUmphhWqhVAv1jJ9g6/iYkKOu9kWQeV5wykT7ilxHfSVMJg3aid9WwQaC
 mngnr/fY23WQBzDQzPZ264ylgZfPqforP2wnxgT1ijE97hoyhfo5h0qyiosOrKtEfP28FKEuuOu
 nCBB0JhwQEPhtJTpwyZFGbKHyhUfVertUxWgWXcWmRlGntsfakW1qS2qqPvMhxQsnLfHZUGcBVV
 wcUOTiTaTteMEz/Xyhs97A3kPZFiVyO4lm/gXHE9wxUcYigdHQ5H/BUJI5EcEY23trAae/UuhS8
 gh8rifmqbI88IMj0dKr2zWoOTdpwxQFkHGpxzBoEwHmz5IQuYr5Q7KfA738zDZPYfchkGr2W8RV
 sAz4VHXqN+HKvDsMWt0OkAf5BT45ffswRv1N6QR+nwpGz9xGSyETWpH9aFDBMG+VSkTR98oTygZ
 3o6tfAxHmegxfJvkTS2OcnrNz3f9VylJ/u6wZzgs37qWceB6U6l3W1b1OfzpLll7hZ4UsZNizv+
 j3W/bB0+m9FAqb43+qBYUmyHUXdUaKhGDYmpnlTOcAX71f0Rp8ZIZ9QbHrO6pld1q+nabpGhxVC
 3J+8Pvc7xVMOpUA==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPU has a timer, one of the pieces of information
we need to pass into GSP init later is the timer offset.
    
This series just adds support for setting up the timer
on Turing+, with hals for Turing and Hopper.
    
Right now it calculates the value to send to GSP but
the code to send it will be added later.
    
For some hardware variants sending a proper value
is required for GSP init to succeed.
    
Dave.

---
Dave Airlie (2):
      rust/timer: expose as_nanos for clock sources.
      gpu: nova-core: add support for GPU timer block.

 drivers/gpu/nova-core/gpu.rs             |  5 +++
 drivers/gpu/nova-core/nova_core.rs       |  1 +
 drivers/gpu/nova-core/regs.rs            | 40 +++++++++++++++++++++
 drivers/gpu/nova-core/timer.rs           | 37 +++++++++++++++++++
 drivers/gpu/nova-core/timer/hal.rs       | 32 +++++++++++++++++
 drivers/gpu/nova-core/timer/hal/gh100.rs | 61 ++++++++++++++++++++++++++++++++
 drivers/gpu/nova-core/timer/hal/tu102.rs | 55 ++++++++++++++++++++++++++++
 rust/kernel/time.rs                      |  3 +-
 8 files changed, 233 insertions(+), 1 deletion(-)
---
base-commit: 3497a403264b094ebd61b8b755165d56e7d9dc37
change-id: 20261026-drm-rust-next-d81ce0f4ecdf

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

