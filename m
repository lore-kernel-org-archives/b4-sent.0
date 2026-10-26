From: Nicola Nicodemo <nicola084@gmail.com>
Date: Mon, 26 Oct 2026 20:39:52 +0100
Subject: [PATCH] platform/x86: samsung-galaxybook: Accept performance mode
 set without success code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-galaxybook-perfmode-set-v1-1-9524f21a08d1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMOw7CMBCE4atEW7OSbRGQuAqisJ1xWB5x5A0oK
 MrdY6CY4ivmX0hRBEqnZqGCt6jkocLuGopXP/Rg6arJGXewddz7h58/Iec7jyjpmTuwYuIYbNi
 beDSuTVTfY0GS+Vc+X/7WV7ghTt8cresG7NnKunsAAAA=
X-Change-ID: 20261026-galaxybook-perfmode-set-cb1b40c7025f
To: Joshua Grisham <josh@joshuagrisham.com>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nicola Nicodemo <nicola084@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793043592; l=6032;
 i=nicola084@gmail.com; s=20261026; h=from:subject:message-id;
 bh=Hmna7VLOcgJWMb26qFyvn/juzCuSuN+yBlxqdXfTQfw=;
 b=FHlK2zB3pS3B3ImsB7xjU6aHHWeIsChyP1WlBpMUJVc4UjcXGR559kU3Rakr7fyawpgYGXWua
 ONRSg5xNqjeClm4xofPBynS7nLq6guTzWSYGBIjuTUz1nUI7aJ69cgM
X-Developer-Key: i=nicola084@gmail.com; a=ed25519;
 pk=qxnxpsv7febRPhFBBsg97s3+9R0jmexxirZUqtaQFPQ=
X-Endpoint-Received: by B4 Relay for nicola084@gmail.com/20261026 with auth_id=1329
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Galaxy Book (NP750XDA, SAM0428) the performance mode SET call
applies the new mode, but the firmware never writes the 0xaa success
code to RFLG in its response. The relevant part of the DSDT
(\_SB.SCAI.CSXI -> HIPF) is:

    Case (0x02)     /* GET */
    {
        IOB0 = BEST
        RFLG = 0xAA
    }
    Case (0x03)     /* SET */
    {
        PRVM = BEST
        BEST = IOB0
        Switch (BEST)
        {
            ... /* update EC and DPTF state, no RFLG */
        }
    }

The platform profile probe ends by setting the balanced mode, so the
missing success code makes the probe fail, platform profile
registration fails and, as that error is fatal, the whole driver fails
to probe:

    acpi SAM0428:00: failed to execute CSXI; device did not respond with success code 0xaa
    samsung-galaxybook SAM0428:00: platform_profile probe failed
    samsung-galaxybook SAM0428:00: error -ENXIO: failed to initialize platform profile

This also takes down the features that work fine on this device: the
battery charge control end threshold and the power_on_lid_open and
block_recording firmware attributes.

When the SET response has no success code, read the mode back with GET
and treat the SET as successful if the mode was applied. To do this
without logging an error on every mode change, split the evaluation of
the ACPI method out of galaxybook_acpi_method() into
galaxybook_acpi_evaluate(), which does not check the response codes.

With this change the driver probes on the NP750XDA, the low-power,
quiet, balanced and performance profiles can be selected and read back,
and the battery threshold and firmware attributes work.

Fixes: 56f529ce4370 ("platform/x86: samsung-galaxybook: Add samsung-galaxybook driver")
Signed-off-by: Nicola Nicodemo <nicola084@gmail.com>
---
Tested on a Galaxy Book NP750XDA (BIOS P22CFD.047.240905.HQ, 09/05/2024).
---
 drivers/platform/x86/samsung-galaxybook.c | 75 +++++++++++++++++++++++--------
 1 file changed, 57 insertions(+), 18 deletions(-)

diff --git a/drivers/platform/x86/samsung-galaxybook.c b/drivers/platform/x86/samsung-galaxybook.c
index 99f72b204..8134fcfc6 100644
--- a/drivers/platform/x86/samsung-galaxybook.c
+++ b/drivers/platform/x86/samsung-galaxybook.c
@@ -220,8 +220,12 @@ static const guid_t performance_mode_guid =
  * ACPI method handling
  */
 
-static int galaxybook_acpi_method(struct samsung_galaxybook *galaxybook, acpi_string method,
-				  struct sawb *buf, size_t len)
+/*
+ * Evaluate the method and copy its response into buf without checking the
+ * response codes; most callers want galaxybook_acpi_method() instead.
+ */
+static int galaxybook_acpi_evaluate(struct samsung_galaxybook *galaxybook, acpi_string method,
+				    struct sawb *buf, size_t len)
 {
 	struct acpi_buffer output = {ACPI_ALLOCATE_BUFFER, NULL};
 	union acpi_object in_obj, *out_obj;
@@ -254,20 +258,6 @@ static int galaxybook_acpi_method(struct samsung_galaxybook *galaxybook, acpi_st
 		err = -EPROTO;
 		goto out_free;
 	}
-	if (out_obj->buffer.pointer[GB_SAWB_RFLG_POS] != GB_RFLG_SUCCESS) {
-		dev_err(&galaxybook->acpi->dev,
-			"failed to execute %s; device did not respond with success code 0x%x\n",
-			method, GB_RFLG_SUCCESS);
-		err = -ENXIO;
-		goto out_free;
-	}
-	if (out_obj->buffer.pointer[GB_SAWB_GB_GUNM_POS] == GB_GUNM_FAIL) {
-		dev_err(&galaxybook->acpi->dev,
-			"failed to execute %s; device responded with failure code 0x%x\n",
-			method, GB_GUNM_FAIL);
-		err = -ENXIO;
-		goto out_free;
-	}
 
 	memcpy(buf, out_obj->buffer.pointer, len);
 	err = 0;
@@ -277,6 +267,31 @@ out_free:
 	return err;
 }
 
+static int galaxybook_acpi_method(struct samsung_galaxybook *galaxybook, acpi_string method,
+				  struct sawb *buf, size_t len)
+{
+	int err;
+
+	err = galaxybook_acpi_evaluate(galaxybook, method, buf, len);
+	if (err)
+		return err;
+
+	if (buf->rflg != GB_RFLG_SUCCESS) {
+		dev_err(&galaxybook->acpi->dev,
+			"failed to execute %s; device did not respond with success code 0x%x\n",
+			method, GB_RFLG_SUCCESS);
+		return -ENXIO;
+	}
+	if (buf->gunm == GB_GUNM_FAIL) {
+		dev_err(&galaxybook->acpi->dev,
+			"failed to execute %s; device responded with failure code 0x%x\n",
+			method, GB_GUNM_FAIL);
+		return -ENXIO;
+	}
+
+	return 0;
+}
+
 static int galaxybook_enable_acpi_feature(struct samsung_galaxybook *galaxybook, const u16 sasb)
 {
 	struct sawb buf = {};
@@ -581,6 +596,8 @@ static int performance_mode_acpi_set(struct samsung_galaxybook *galaxybook,
 				     const u8 performance_mode)
 {
 	struct sawb buf = {};
+	u8 current_mode;
+	int err;
 
 	buf.safn = GB_SAFN;
 	buf.sasb = GB_SASB_PERFORMANCE_MODE;
@@ -589,8 +606,30 @@ static int performance_mode_acpi_set(struct samsung_galaxybook *galaxybook,
 	buf.subn = GB_SUBN_PERFORMANCE_MODE_SET;
 	buf.iob0 = performance_mode;
 
-	return galaxybook_acpi_method(galaxybook, GB_ACPI_METHOD_PERFORMANCE_MODE,
-				      &buf, GB_SAWB_LEN_PERFORMANCE_MODE);
+	err = galaxybook_acpi_evaluate(galaxybook, GB_ACPI_METHOD_PERFORMANCE_MODE,
+				       &buf, GB_SAWB_LEN_PERFORMANCE_MODE);
+	if (err)
+		return err;
+
+	if (buf.rflg == GB_RFLG_SUCCESS)
+		return 0;
+
+	/*
+	 * Some devices (e.g. Galaxy Book 750XDA) apply the new performance mode
+	 * but never set the success code in their response, so read the mode
+	 * back to check whether it was applied.
+	 */
+	err = performance_mode_acpi_get(galaxybook, &current_mode);
+	if (err)
+		return err;
+
+	if (current_mode != performance_mode) {
+		dev_err(&galaxybook->platform->dev,
+			"failed to set performance mode 0x%x\n", performance_mode);
+		return -ENXIO;
+	}
+
+	return 0;
 }
 
 static int get_performance_mode_profile(struct samsung_galaxybook *galaxybook,

---
base-commit: 9d3475065167197742b0882aff21cf8e78393277
change-id: 20261026-galaxybook-perfmode-set-cb1b40c7025f

Best regards,
--  
Nicola Nicodemo <nicola084@gmail.com>

