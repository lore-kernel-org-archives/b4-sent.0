From: Kurt Borja <kuurtb@gmail.com>
Subject: [PATCH v4 0/2] platform/x86: alienware-wmi-wmax: Add support for
 GPIO methods
Date: Mon, 05 May 2025 15:43:30 -0300
Message-Id: <20250505-awcc-gpio-v4-0-edda44c3a0dc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANIGGWgC/13M0QrCIBTG8VcZXmd4jrqxrnqP6MKp24SWQ8OKs
 XfPjSDp8juc338h0QZnIzlVCwk2uej8PQ9xqIge1X2w1Jm8CTKUTACn6qk1HWbnKYoOeqmlqA2
 S/D8H27vX3rpc8x5dfPjw3tMJtuu3gmUlAWUUaqYAOs37Vp2HSbnbUfuJbJWEpWxKiVnqhgNve
 CcNw3/Jf1IyLCXP0qpWtRwNAIpSruv6ARus38EWAQAA
X-Change-ID: 20250413-awcc-gpio-24b1f5c546d2
To: Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Armin Wolf <W_Armin@gmx.de>
Cc: Gabriel Marcano <gabemarcano@yahoo.com>, 
 platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1934; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=LbuYk15hVptDZsuRbMqI5YgO3RsvLpjnt+XuoYI2XaI=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBmSbFcldaW/3n4TcmjDk3sC+ev23X+1sN7WfxrvCVm+6
 MubvXeEdJSyMIhxMciKKbK0Jyz69igq763fgdD7MHNYmUCGMHBxCsBEXCIYGT7t3LY4znne4d0n
 dVg2hLmLxN6Zr3b97PM8tkqp/LTNPb8ZGV6J+qybV/jl8brFRcabEo/0xEj9dmmasyY10yi7UmQ
 qPzsA
X-Developer-Key: i=kuurtb@gmail.com; a=openpgp;
 fpr=54D3BE170AEF777983C3C63B57E3B6585920A69A
X-Endpoint-Received: by B4 Relay for kuurtb@gmail.com/default with auth_id=387
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

I found a great blog post [1], which described the reverse engineering
process of the GPIO control methods present on this device.

In summary, these methods expose some debugging capabilities of the RGB
lighting controller present on Dell gaming laptops. See [Patch 2] for
more info.

Exposing these methods to DebugFS is useful for developers exploring
this RGB controllers (myself included).

Thanks for your feedback!

[1] https://gabriel.marcanobrady.family/blog/2024/12/16/dell-g5-5505-se-acpi-or-figuring-out-how-to-reset-the-rgb-controller/

Signed-off-by: Kurt Borja <kuurtb@gmail.com>
---
Changes in v4:
- Reuse name[] for all file a directory names in awcc_debugfs_init()
- Reword commit message to correctly reflect previous changes
- Link to v3: https://lore.kernel.org/r/20250502-awcc-gpio-v3-0-ea9a932d1124@gmail.com

Changes in v3:
- Create pinX files dynamically, based on GPIO pin count
- Added note on dummy input arguments in Documentation
- Link to v2: https://lore.kernel.org/r/20250427-awcc-gpio-v2-0-c731373b5d02@gmail.com

Changes in v2:
- Dropped module parameter
- Added ABI documentation to Patch 1
- Small improvements to documentation based on Armin's comments
- Improved Pin description table format
- Link to v1: https://lore.kernel.org/r/20250423-awcc-gpio-v1-0-160a11bc3f9a@gmail.com

---
Kurt Borja (2):
      platform/x86: alienware-wmi-wmax: Expose GPIO debug methods
      Documentation: wmi: alienware-wmi: Add GPIO control documentation

 Documentation/ABI/testing/debugfs-alienware-wmi |  20 +++++
 Documentation/wmi/devices/alienware-wmi.rst     |  82 ++++++++++++++++++-
 drivers/platform/x86/dell/alienware-wmi-wmax.c  | 104 +++++++++++++++++++++++-
 3 files changed, 201 insertions(+), 5 deletions(-)
---
base-commit: 67e2635fe0cca5f0383c0780db986d8237e83f0a
change-id: 20250413-awcc-gpio-24b1f5c546d2

Best regards,
-- 
 ~ Kurt

