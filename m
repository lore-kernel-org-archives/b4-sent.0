From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Subject: [PATCH v2 0/3] Add support for attaching a regulator to w1: ds2482
Date: Fri, 22 Nov 2024 09:53:56 +0100
Message-Id: <20241122-ds2482-add-reg-v2-0-a5a03ee74da7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKRGQGcC/13MwQrCMAzG8VcZORtpY53Tk+8hO3RttgXcKq0MZ
 fTdrQMv5vYPfL8VEkfhBJdqhciLJAlzCdpV4EY7D4ziSwMpMroc+kSmIbTeY+QBe9YHUsr6k6+
 hjB6Re3lt4K0tPUp6hvje/EV/vz/q+E8tGhU615jubDurqb4Ok5X73oUJ2pzzB9ApMhKsAAAA
X-Change-ID: 20241111-ds2482-add-reg-fe13200ad7d6
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732265684; l=833;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=7rzMvx48n11Ga+k4795VyVqRvaffhTq48wBjDhlzNNo=;
 b=/3H2DNmW19Y6vUUYwxh+ll7I0BRp/3t9orrqSBiaWcUwL5Y/NrWsX7KRoDq04OA/QiTPOpBGK
 GFwHYefiy5KB5KhbaAP3ux9rPEEdYxnJoBNHMgP3xcZ5Lw+u90W4qd8
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sending a new version based on our discussion.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
Changes in v2:
- Removed property description
- Changed commit message of binding commit
- Link to v1: https://lore.kernel.org/r/20241115-ds2482-add-reg-v1-0-cc84b9aba126@gmail.com

---
Kryštof Černý (3):
      w1: ds2482: Add regulator support
      w1: ds2482: Fix datasheet URL
      dt-bindings: w1: ds2482: Add vcc-supply property

 .../devicetree/bindings/w1/maxim,ds2482.yaml       |  2 ++
 drivers/w1/masters/ds2482.c                        | 23 +++++++++++++++++++++-
 2 files changed, 24 insertions(+), 1 deletion(-)
---
base-commit: 6d59cab07b8d74d0f0422b750038123334f6ecc2
change-id: 20241111-ds2482-add-reg-fe13200ad7d6

Best regards,
-- 
Kryštof Černý <cleverline1mc@gmail.com>

