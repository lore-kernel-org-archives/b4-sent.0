From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH v3 0/2] pvscsi: fix endianness issues
Date: Fri, 10 Jul 2026 03:21:38 +0800
Message-Id: <20260710-pvscsi-endianness-v3-0-27fe1c4d1f6e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAML0T2oC/33NTQ6CMBCG4auQrq1py19h5T2MC9oOMIkU0jGNh
 nB3CxtdGJfvl8wzKyMICMTabGUBIhLOPkV+ypgdOz8AR5eaKaEqUYmSL5EsIQfvsPMeiLgVLte
 N06ougKW7JUCPz8O83lKPSI85vI4XUe7rPy1KLrkRpi9qZURfNpdh6vB+tvPEdi2qj1BL8UtQS
 bClVFBZrYvGfAvbtr0BUvBDjfQAAAA=
X-Change-ID: 20260605-pvscsi-endianness-c0d389d8274e
To: qemu-devel@nongnu.org
Cc: Paolo Bonzini <pbonzini@redhat.com>, Fam Zheng <fam@euphon.net>, 
 Dmitry Fleytman <dmitry.fleytman@gmail.com>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Peter Maydell <peter.maydell@linaro.org>, Michael Tokarev <mjt@tls.msk.ru>, 
 Arvind Kumar <arvindkumar@vmware.com>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1294;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=7fLZ2sAA938WMFeMYQpLEfSXXsyNIVRkUXhS+kpqv2U=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqT/TEEgj3Z12khUW0lb7ZUjX2PxpIDuRNR605H
 WRSFhenxEuJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak/0xAAKCRCwMePKe/7Z
 bjySD/0QgQazFzhDj+b308/RfW7n/inCHQYPzKSfTT+iGdqtk4T9+cfQ1gUzBWGo+ZmbS8vThuN
 e8Tl+fztqDq/cXg4Tct8fpUOsx+eLWAGxQUy04UimOObx7efc8+HqE41vTQHey0qSi4LaINy03y
 s3bjf0h1pS/iFyeQTJkNfUi6ZDuxmpaEjGXelsnJxyvhXDjdU92PVaY507AAv59Tr+Fx6Ru/IZB
 qI7MJeolnzs7oBTyQCWdFYaZ7sf0kzdAL7qp2A30uWt2ftsObQG8MuSGSaY2DuB4XG9ilPmPlQr
 U8VGLBT14DlJX8IIRMU/Fpx87XpFO3f4fw1yKisg86XpZNZbiVNCXDL76Xnz2aD0xA169Z252SU
 yBhJdGmOAOF51fYwI8vdhTYqroE6zSL4FOBT064icyCEOToFiC+xpNNlC1yv9UCgPbcosoP/XNH
 EpN7SvWciQWby3uxBULQLP5GkK4sTCAxld95dO6sIo1d6YT8mg4tbo1a6V12X9jeQUzl4T20kuq
 FQ+mrx0VEZrDa2Qs218NY1jpfdZD1DiFUIs8/AvlJ7Z3kqPt/Fo3tA4wWhACOqWGuk7CZOmsA4o
 wRAhF4+XkUx31Ngw+Ik3Bxuq8iQN6bK9B9HoL0wf6cWDFp4a8H7d+LQQGRAd4IwAXktI01is++P
 JU3ZDGzcm6eNGgQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series fixes the endianness issues in the pvscsi device
emulation and clarfies the endianness of pvscsi data structures.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v3:
- Remove the unnecessary struct keyword for the structs that have
  been already typedef-ed.
- Add a comment in vmw_pvscsi.h to explain the endianness of pvscsi
  data structures.
- Link to v2: https://lore.kernel.org/qemu-devel/20260710-pvscsi-endianness-v2-1-c512e6c8849b@gmail.com

Changes in v2:
- Assume pvscsi is little-endian instead of native-endian, and thus
  replace tswap*() with le*_to_cpu() and cpu_to_le*() to convert the
  endianness of pvscsi data structures to/from CPU endianness.
- Link to v1: https://lore.kernel.org/qemu-devel/20260605-pvscsi-endianness-v1-1-b0bf472b0f59@gmail.com

---
Miao Wang (2):
      pvscsi: translate data endianness
      pvscsi: add a comment to explain the endianness

 hw/scsi/vmw_pvscsi.c | 57 +++++++++++++++++++++++++++++++++++++++++++++++++++-
 hw/scsi/vmw_pvscsi.h | 14 +++++++++++++
 2 files changed, 70 insertions(+), 1 deletion(-)
---
base-commit: 29c042c6e9d4a09d4a0ac3fa54aeb7ee08ce0bdc
change-id: 20260605-pvscsi-endianness-c0d389d8274e

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

