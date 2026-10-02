From: Miguel Garcia <miguelgarciaroman8@gmail.com>
Date: Fri, 02 Oct 2026 16:46:20 +0200
Subject: [PATCH v2] ACPI: device-id: document struct acpi_device_id
To: rafael@kernel.org, u.kleine-koenig@baylibre.com
Cc: kmehltretter@gmail.com, andriy.shevchenko@linux.intel.com, 
 corbet@lwn.net, linux-acpi@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Miguel Garcia <miguelgarciaroman8@gmail.com>
Message-ID: <179095238036.1979087.7916496223328936920.acpi-device-id-docs-v2@gmail.com>
X-Mailer: b4 0.13.0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790952380; l=2136;
 i=miguelgarciaroman8@gmail.com; s=default; h=from:subject:message-id;
 bh=sE0IoEcH5Ya0LQYTgZVL1op2QwyPf67lPf4oqCTCPP8=;
 b=duxYzq36gHOld9OWlUN/wZIC3SIgrxKd0JnSRug5alTTW7QdgJ4VPguHyntvDeBg8iX5vB200
 HR6yNwUP7WzBLhON0vIVsFZU8pxl5+n20VYZyuPQZE+Z6Dp/jy96/Ry
X-Developer-Key: i=miguelgarciaroman8@gmail.com; a=ed25519;
 pk=EtrxRdQ/icT1qmJwjNNAVoBUhKKWwrhU2m6QT/xu6bM=
X-Endpoint-Received: by B4 Relay for miguelgarciaroman8@gmail.com/default with auth_id=1101
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct acpi_device_id lacks kernel-doc, so extracting documentation from
its header describes ACPI_DEVICE_CLASS() but not the matching table entry.

Document the four members, ID and class-code matching, and the table
terminator. This complements the documentation header-split work
without changing its include directives.

Link: https://lore.kernel.org/all/aqEWUBf1pewPP_K2@monoceros/
Assisted-by: LLM
Signed-off-by: Miguel Garcia <miguelgarciaroman8@gmail.com>
---
Changes in v2:
- Use ACPI_DEVICE_CLASS() in the commit message, as requested by Andy.
- Move the drafting and validation notes below the commit message.
- Describe the related header-split work without assuming its status.
- No change to the source diff.

v1: https://lore.kernel.org/r/20260913095111.2543502-1-miguelgarciaroman8@gmail.com/

An LLM drafted this comment and changelog after being asked to address
the missing documentation noted in the header-split discussion. The
field descriptions were checked against the ACPI matching code. The
extracted documentation passes kernel-doc and a focused Sphinx HTML
build with warnings treated as errors; checkpatch reports no warnings.

 include/linux/device-id/acpi.h | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/include/linux/device-id/acpi.h b/include/linux/device-id/acpi.h
index 65800cefd..8c3b30ebf 100644
--- a/include/linux/device-id/acpi.h
+++ b/include/linux/device-id/acpi.h
@@ -9,6 +9,16 @@ typedef unsigned long kernel_ulong_t;
 
 #define ACPI_ID_LEN	16
 
+/**
+ * struct acpi_device_id - ACPI device matching table entry
+ * @id: NUL-terminated hardware ID (_HID) or compatible ID (_CID) to match.
+ * @driver_data: Data private to the driver.
+ * @cls: PCI-defined class, subclass and programming interface code (_CLS).
+ * @cls_msk: Mask selecting the class-code fields to match.
+ *
+ * Use @id for ID matching or ACPI_DEVICE_CLASS() for class-code matching.
+ * Terminate the table with an entry whose @id is empty and @cls is zero.
+ */
 struct acpi_device_id {
 	__u8 id[ACPI_ID_LEN];
 	kernel_ulong_t driver_data;
-- 
2.43.0


