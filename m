From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Subject: [PATCH v5 0/4] iio: accel: mma8452: use modern coding style and
 resource cleanup
Date: Sat, 08 Aug 2026 22:28:12 +0530
Message-Id: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACRgd2oC/4WOQQ6CMBREr0K69ptSW4KuvIdhUcovfGNp0yLRE
 O5uwbh2NXnJ5M0sLGEkTOxSLCziTIn8mEEdCmYGPfYI1GVmgouKV7yEUoEOEYIDIg/O6VoqAbO
 ECV0A5JLL+qxbNCeWHSGipdfuvzVfTs/2jmbapFtjoDT5+N4PzHLr/bbEn62cHETVVZ21tTVKX
 Xun6XE03rFmXdcPfpp+cNwAAAA=
X-Change-ID: 20260601-15-apr-pm-iio-mma8452-v4-temp-e040489abec3
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786208304; l=2244;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=Md3IGD9Xm80hkMLNc996V9V5s2coVfbpVTtCctkt6Bs=;
 b=W0aSnZevebmJb3aO/DDGTZWv8mM5fBSXzKW8C2JqKC8ykHTzFupFga8CDwtkkE3YfmAsDYVkP
 2hMJjbGkBh9BsglM0wM6PLd7il8xEpITVjbTeHzayy+vGm9xUUiYZ3z
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This series contains a nuber of small fixes, cleanup and improvements
for the mma8452 accelerometer driver.

The changes modernize macro like mutex with guard(), bulk regulator,
IIO_DEV_ACQUIRE_DIRECT_MODE() and etc.

Changes in v5:
- Drop the PM runtime handling patch, as suitable hardware is not
  available to properly validate the PM state transitions.
- Apply reviewed tags.
- Rebase series onto the latest iio/testing branch.
- Link to v4: https://patch.msgid.link/20260602-15-apr-pm-iio-mma8452-v4-temp-v4-0-26d6dff8fc55@gmail.com
Changes in v4:
- Part of the series already merged into the IIO tree; rebase the
  remaining patches onto the latest iio/testing branch.
- Link to v3: https://lore.kernel.org/all/20260602-15-apr-pm-iio-mma8452-v4-temp-v4-0-26d6dff8fc55@gmail.com
Changes in v3:
- Following input from Andy and Jonathan added new changes as following
  0001: handle return value to have proper error propagation
  0002: use non-devm API to maintain resource management LIFO order
  0006: convert individual regulator using bulk regulator API
  0009: use IIO cleanup helper for DIRECT_MODE
- Address kernel coding stype specific review comment
- Reorder local struct device and dev_err_probe change
v2 series -> https://lore.kernel.org/all/20260422165643.2148195-1-sanjayembedded@gmail.com/
Changes in v2:
- 0005: address review comment from Andy and Geert
  and use DEFINE_RUNTIME_DEV_PM_OPS macro
- Added new cleanup channges in mma8452 driver

No functional behavior changes are intended.

Testing:
  - Compiled with W=1
  - Build-tested on QEMU x86_64

Feedback and reviews are very welcome.

---
Sanjay Chitroda (4):
      iio: accel: mma8452: convert to bulk regulator usage
      iio: accel: mma8452: use local struct device
      iio: accel: mma8452: Use IIO cleanup helpers
      iio: accel: mma8452: use guard() to release mutexes

 drivers/iio/accel/mma8452.c | 145 +++++++++++++++++---------------------------
 1 file changed, 54 insertions(+), 91 deletions(-)
---
base-commit: 350d1fb9204b13c5f95e511e98b8bcb47574d425
change-id: 20260601-15-apr-pm-iio-mma8452-v4-temp-e040489abec3

Best regards,
--  
Sanjay Chitroda <sanjayembeddedse@gmail.com>

