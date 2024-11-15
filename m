From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Subject: [PATCH 0/3] Add support for attaching a regulator to w1: ds2482
Date: Fri, 15 Nov 2024 15:58:03 +0100
Message-Id: <20241115-ds2482-add-reg-v1-0-cc84b9aba126@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHthN2cC/x2MMQqAMAwAv1IyG2hjUfEr4lBM1CwqDYhQ/LvF2
 264K2CSVQxGVyDLrabnUSU0DpY9HZugcnUgTzFUkI3iQJiYMcuGq4SWvE/ccwc1urKs+vzDaX7
 fDxCNDJZgAAAA
X-Change-ID: 20241111-ds2482-add-reg-fe13200ad7d6
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731682735; l=959;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=i9M5fv+9635ob3cC6vzKXM4ms1fR6YAYupYhw4RUh4E=;
 b=+WV9BrdehkaUq7wCfOEIm5som3iiUHVsVkRxiOeem+Kvwiz7juuIjAVvzxtm7Tyg5o9nKhqnY
 MjmiBDgVpIsAxBPL4TU7yjFAsXv3Esu20kNFkf9NQXbGpYJeLmDe6Xg
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a support for attaching a regulator to the ds2482 I2C to 1-Wire converter.
The device I work on has a separate regulator for this chip and using always on regulator
is not working well, so I tried to make a proper solution. This is my first kernel code
modification, so any feedback will be highly appreciated. Patch was tested on the real hw.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
Kryštof Černý (3):
      w1: ds2482: Add regulator support
      w1: ds2482: Fix datasheet URL
      dt-bindings: w1: ds2482: Add vcc-supply property

 .../devicetree/bindings/w1/maxim,ds2482.yaml       |  3 +++
 drivers/w1/masters/ds2482.c                        | 23 +++++++++++++++++++++-
 2 files changed, 25 insertions(+), 1 deletion(-)
---
base-commit: 6d59cab07b8d74d0f0422b750038123334f6ecc2
change-id: 20241111-ds2482-add-reg-fe13200ad7d6

Best regards,
-- 
Kryštof Černý <cleverline1mc@gmail.com>

