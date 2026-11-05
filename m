From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH v4 0/2] nova-core: add initial support for gpu timer (v4)
Date: Thu, 05 Nov 2026 13:07:00 +1000
Message-Id: <20261105-nova-timer-v4-0-45a7c121d4de@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23MSw6CMBSF4a2QO7amr4A4ch/GQUtv5Q6gpm0aD
 WHvFkaSODwn+f4FEkbCBNdmgYiFEoW5Dn1qYBjN/ERGrm6QXLZCcMnmUAzLNGFkXtveoZKdNgI
 qeEX09N5j90fdI6Uc4mdvF7G9fzNFMM6s0h0a12rd9reIbjT5PIQJtk5Rv1YdrKqWD7631uDFu
 6Nd1/ULOc7xM+EAAAA=
X-Change-ID: 20261102-nova-timer-f4b9de3274a1
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1607; i=airlied@redhat.com;
 h=from:subject:message-id; bh=gmzSh2vYZ5T/6/GkbD9fkp9oFKW0guaRJJHQCAjtZMI=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq6/Ldh79zNkPvkT9lxN+SDhjUzWUJLw0mA2eso
 OTyMjfAqU+JAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCauvy3QAKCRAMdPNZecSG
 vlHvEACOX7OQGTHa/HXbcHfQeXhUh9ugawpcZnUOroGXIfdKcIyEiXEd/Xt1YC7QYNvHJlO+jsO
 lyEkikNb4YiKAtHHakVagbECLnrEwBlFCYScN1if79AdMptzucYoX0hyYeanPlLhyccEk/UkPwR
 Pqmi83O+M+iyw/6xH5PG5gZKecCZcrgyl+PNrCjyE5W6cfMVTXkTgM6c5rXThFUuNdtSTSCrYMz
 4BeeGAk8MWa5QutxXEbUYIrYFZk8ou17vxebG0ix5WwjNXI1VxluI1u+XWoCZnZsI/Sx5cPUSjb
 BWIMhKs1UpmzF7d/to/vsGIdNMh77wMfJ2jOiPrpMAjPM8mpcjc5dLxQEchuIVf3VAePUDcsQ9Q
 StTPHSenra6m4BhUYYr5PcXT4lmkgkxIufkTMPBhx9EcnBvpFdLcYTL8W7t8H8j6e6L3jb/+JkX
 h1DxaochVusW8Ya0vurPl2BJ1KJG8n/z/q1ooguurRfRCwt7vjzoXQ+yS1+AkwAgndTMZ8rKH8n
 /gvW4c5xanvg0qEkkxaenshbDuafefscnMuiIlKeQ+6IH+hPPjGHwFtKF40aoJvYH7ceSyrD+u+
 YGjxoiA6joscR1Zq78hZOcvpTWlAM/2WGlCsgldSYMc+pHBPIM9CWrD6pZrfLEXlI1GJ/oUXXun
 w8uSVXEAVru/RNw==
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

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
Changes in v4:
- reworked register handling
- used a timerstate.
- Link to v3: https://lore.kernel.org/r/20261103-nova-timer-v3-0-0cf9bbae8fd9@redhat.com

---
Dave Airlie (2):
      rust: time: expose as_nanos for clock sources.
      gpu: nova-core: add support for GPU timer block. (v4)

 drivers/gpu/nova-core/fsp.rs             |  5 +-
 drivers/gpu/nova-core/fsp/regs.rs        | 30 ++++++++++++
 drivers/gpu/nova-core/gpu.rs             |  8 ++++
 drivers/gpu/nova-core/nova_core.rs       |  1 +
 drivers/gpu/nova-core/timer.rs           | 33 +++++++++++++
 drivers/gpu/nova-core/timer/hal.rs       | 27 +++++++++++
 drivers/gpu/nova-core/timer/hal/gh100.rs | 79 ++++++++++++++++++++++++++++++
 drivers/gpu/nova-core/timer/hal/tu102.rs | 53 +++++++++++++++++++++
 drivers/gpu/nova-core/timer/regs.rs      | 82 ++++++++++++++++++++++++++++++++
 rust/kernel/time.rs                      |  3 +-
 10 files changed, 318 insertions(+), 3 deletions(-)
---
base-commit: 3497a403264b094ebd61b8b755165d56e7d9dc37
change-id: 20261102-nova-timer-f4b9de3274a1

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

