From: Ben Zong-You Xie <ben717@andestech.com>
Subject: [PATCH v4 0/3] pwm: add support for Andes platform
Date: Wed, 04 Feb 2026 19:30:40 +0800
Message-Id: <20260204-andes-pwm-v4-0-67016bb13555@andestech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOAtg2kC/32Nyw6CMBBFf8V0bUlnWlpw5X8YF1AGqQmPUEQN4
 d9tMcaVLmaSm9xz7sI8jY48O+wWNtLsvOu7ENR+x2xTdBfirgqZoUAtUChedBV5PtxbDoIKrQG
 stDUL/WGk2j021+n8zv5WXslOURAbjfNTPz63sRliL3oVCMzCGYQEcg2Y5Rx4SZ0Bc9zmJrJNY
 vuWRe2MXzA8oQUokwAaQK3+gvIDpgJQQi5TqZLMKEz1T25d1xdWMcSzJAEAAA==
X-Change-ID: 20260204-andes-pwm-10ea6611c3cf
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770204641; l=3232;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=3Qoag22QfHkljcDoVCkjtyQ2+4W+gOHp2y/mu70bSTc=;
 b=KW5KWM+YBOpWcm4Ri4pd6+VYTq8E60auwgmivEt/zZXM0QIG2zEJH7N0B3Rs/ldPvCGqup0e0
 OphjzW35qx2CRc/CL92tAbgm56kXQNjtd4Az03fJaVHV0U0649lVVPy
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ATCPIT100 is a set of compact multi-function timers, which can be
a simple timer or PWM, or a combination of the timer and the PWM. This
IP block is a core component of the Andes AE350 platform, which serves
as a reference architecture for SoC designs. The QiLai SoC also
integrates this controller.

This device driver was previously part of the Linux Kernel, and the
compatible was its IP name "andestech,atcpit100". However, the driver
and its binding were removed due to the deprecation of the NDS32
architecture [1]. Although Andes now dedicates our effort on RISC-V,
ATCPIT100 is still one of our peripheral IPs, and that's why we are
re-introducing it now. Since only using the IP block name as the
compatible is forbidden now, change the compatible to
"andestech,ae350-pwm" and "andestech,qilai-pwm".

[1] https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=aec499c75cf8e0b599be4d559e6922b613085f8f

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
Changes in v4:
- Updated cover letter title and its commit message.
- (1/3)
    - Updated the compatibles and the binding file name.
    - Added the description to the binding.
    - Corrected device register size.
    - Dropped the changes to the MAINTAINERS file.
- (2/3)
    - Updated the driver name.
    - Made the driver support inversed polarity.
    - Changed the clock selection algorithm.
    - Made the configuration depend on ARCH_ANDES, instead of RISCV. (Krzysztof)
    - Dropped the changes to the MAINTAINERS file.
- (3/3) (new)
    - Collected all changes to the MAINTAINERS file into a single patch.
- Link to v3: https://patch.msgid.link/20250123193534.874256-1-ben717@andestech.com

Changes in v3:
- (1/2):
    - modified the compatible string. (Krzysztof)
- (2/2):
    - added a check for the clock rate to prevent the overflow warning.
      (kernel test robot)
    - removed the unnecessary check in .apply(). (kernel test robot)
- Link to v2: https://patch.msgid.link/20241202060147.1271264-1-ben717@andestech.com

Changes in v2:
- (1/2):
    - changed "title" in the yaml file.
    - removed vendor-specific property, and added clocks property.
- (2/2):
    - added a description for hardware limitations. (Uwe)
    - switched the clock parent depending on the requested setting
      instead of statically configuring the clock source in DT. (Uwe)
- Link to v1: https://patch.msgid.link/20241028102721.1961289-1-ben717@andestech.com

---
Ben Zong-You Xie (3):
      dt-bindings: pwm: add support for AE350 PWM controller
      pwm: add Andes PWM driver support
      MAINTAINERS: add an entry for Andes PWM driver

 .../bindings/pwm/andestech,ae350-pwm.yaml          |  61 ++++
 MAINTAINERS                                        |   6 +
 drivers/pwm/Kconfig                                |  10 +
 drivers/pwm/Makefile                               |   1 +
 drivers/pwm/pwm-andes.c                            | 306 +++++++++++++++++++++
 5 files changed, 384 insertions(+)
---
base-commit: 9321f9d27fbaf6c4f32772fc2620961a0c492135
change-id: 20260204-andes-pwm-10ea6611c3cf

Best regards,
--  
Ben Zong-You Xie <ben717@andestech.com>

