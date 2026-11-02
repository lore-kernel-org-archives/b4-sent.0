From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH 0/2] nova-core: add initial support for gpu timer (v2)
Date: Mon, 02 Nov 2026 17:17:39 +1000
Message-Id: <20261102-nova-timer-v1-0-b347ead64469@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwMj3bz8skTdkszc1CLdNJMky5RUYyNzk0RDJaCGgqLUtMwKsGHRsbW
 1AP5WcfNcAAAA
X-Change-ID: 20261102-nova-timer-f4b9de3274a1
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1359; i=airlied@redhat.com;
 h=from:subject:message-id; bh=RYbXHTs81IbH7HvDGHxYUlQGzPjtXhkoehwsBfu0Hto=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq6DkYDL0yKfyHai+FiOWnD9w9gdYcDqpe6Q8vi
 jeiHuKBDdGJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCaug5GAAKCRAMdPNZecSG
 vnHxEACos1WTmVvpCG78TQF4ByhizPj2/NukKawmojSNAa7FcBoTT47lssoanIRwFuqEE30Zs7d
 5xXGQL9D5L3wM6QX2qsTKYeStri4oMJyz5WyMbs1BggJm4NP9dYHtSfEiv1VmRj6vxR+O5LL4D3
 XK0GsMrr10Epl93z/OGjjaMb4uUPjiiJzdIW3Wi7suGVEcEa6Q2kZkVDACrUrcptTIh0h1JmMkh
 vlHt/FQuIVx3m6ANmxjZrzgubOrrs9mUXoQyBHhmapmrChVX/VZmXilQSvt/Y2p+HAqzjHvZmb8
 PWxPmBi5J8dijwgg2YBJhwcmb5hYXUX5aTajlKiJmaJSzhhiFqX3HcYqG8ASL4Wctgx58opS/Sw
 iG3GqMMjb3AUCHg7vRSUBf98d1N2bEutLJGDeAIHtvCM0RM7pFk7rhc+qJqlB3egs+/4RyPjEw4
 3XweKOvrveAQ/IReinl/dJ9sKQ3iBBwa+5Dh9UAy5gOWGSQfGKOZta8oXtIUnWTB/jI+nHvreAM
 gdLcjjxur2M8G/TQaKLSAmjWjH/Uj6a12sbQZJDkQrFZnFqYgcWpO17oOHCcbzFtadDnIC3kms7
 jy9FOxopeYWvx+N0dRvfP1MirO/k9ave+r6bKmOZCjFU0vjBtdtzzMfGCSSuuiIXG+rKjt1rIyy
 vTsgsZCeV1IVY+A==
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

v2 changes on second patch.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
Dave Airlie (2):
      rust: time: expose as_nanos for clock sources.
      gpu: nova-core: add support for GPU timer block. (v2)

 drivers/gpu/nova-core/gpu.rs             |  5 +++
 drivers/gpu/nova-core/nova_core.rs       |  1 +
 drivers/gpu/nova-core/timer.rs           | 33 ++++++++++++++
 drivers/gpu/nova-core/timer/hal.rs       | 28 ++++++++++++
 drivers/gpu/nova-core/timer/hal/gh100.rs | 76 ++++++++++++++++++++++++++++++++
 drivers/gpu/nova-core/timer/hal/tu102.rs | 56 +++++++++++++++++++++++
 drivers/gpu/nova-core/timer/regs.rs      | 64 +++++++++++++++++++++++++++
 rust/kernel/time.rs                      |  3 +-
 8 files changed, 265 insertions(+), 1 deletion(-)
---
base-commit: 3497a403264b094ebd61b8b755165d56e7d9dc37
change-id: 20261102-nova-timer-f4b9de3274a1

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

