From: Atanas Kunchev <atanaskunchev@proton.me>
Date: Sat, 24 Oct 2026 11:23:38 +0300
Subject: [PATCH] driver core: attribute_container: document return values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-kdoc-attrcont-v1-1-b18627a05e97@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyMT3eyU/GTdxJKSouT8vBLdFPMUU/MkCzMTA2MjJaCegqLUtMwKsHn
 RsbW1AOHxB+1fAAAA
X-Change-ID: 20261024-kdoc-attrcont-d7d57b864032
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>
Cc: driver-core@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Atanas Kunchev <atanaskunchev@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792830221; l=3346;
 i=atanaskunchev@proton.me; h=from:subject:message-id;
 bh=LIsbRaaKztkyCnOK3iDcNAWRh1j3Q2eW+S5qjF582+M=;
 b=4w9Omiw0e+55w72tL01eC17sNjj91rSv3A0ue5icOC4YpctjQQD2wbQtfhH9nqBh10pxcfuXS
 JRDMh7gQGV0DKL7RfwjU2HYQjfoK8gc5pgU6cFyJghzKkmAcymL9HYE
X-Developer-Key: i=atanaskunchev@proton.me; a=ed25519;
 pk=UZOV7XzSdjoak/BahXi4m/UsbdgtIb1vQI3+u1lAHOc=
X-Endpoint-Received: by B4 Relay for atanaskunchev@proton.me/default with auth_id=1293
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the missing "Return:" descriptions to the kernel-doc comments of
the attribute_container functions.

Signed-off-by: Atanas Kunchev <atanaskunchev@proton.me>
---
Fix the missing return value descriptions reported by kernel-doc -Wall.
---
 drivers/base/attribute_container.c | 19 ++++++++++++++++++-
 1 file changed, 18 insertions(+), 1 deletion(-)

diff --git a/drivers/base/attribute_container.c b/drivers/base/attribute_container.c
index 3c456374247b..d2ce3a2abcab 100644
--- a/drivers/base/attribute_container.c
+++ b/drivers/base/attribute_container.c
@@ -48,7 +48,7 @@ static void internal_container_klist_put(struct klist_node *n)
  *
  * @classdev: the class device created by attribute_container_add_device.
  *
- * Returns the container associated with this classdev.
+ * Return: the container associated with this classdev.
  */
 struct attribute_container *
 attribute_container_classdev_to_container(struct device *classdev)
@@ -86,6 +86,9 @@ EXPORT_SYMBOL_GPL(attribute_container_register);
  * attribute_container_unregister - remove a container registration
  *
  * @cont: previously registered container to remove
+ *
+ * Return: 0 on success, or -EBUSY if the container still has class
+ * devices registered.
  */
 int
 attribute_container_unregister(struct attribute_container *cont)
@@ -290,6 +293,10 @@ do_attribute_container_device_trigger_safe(struct device *dev,
  * undo the partial work that has been done, on previous classdev.  It
  * is guaranteed that either they all succeeded, or none of them
  * succeeded.
+ *
+ * Return: 0 if @fn succeeded for every matching classdev, or the first
+ * error returned by @fn. In that case @undo, if given, has been run on
+ * the classdevs already processed.
  */
 int
 attribute_container_device_trigger_safe(struct device *dev,
@@ -382,6 +389,9 @@ attribute_container_device_trigger(struct device *dev,
  *
  * This simply creates all the class device sysfs files from the
  * attributes listed in the container
+ *
+ * Return: 0 on success (including when the container has no attributes),
+ * or a negative error code if creating the sysfs files failed.
  */
 int
 attribute_container_add_attrs(struct device *classdev)
@@ -417,6 +427,10 @@ attribute_container_add_attrs(struct device *classdev)
  * This performs essentially the same function as device_add except for
  * attribute containers, namely add the classdev to the system and then
  * create the attribute files
+ *
+ * Return: 0 on success, or a negative error code from device_add() or
+ * from creating the attribute files. In the latter case the class device
+ * is removed again with device_del().
  */
 int
 attribute_container_add_class_device(struct device *classdev)
@@ -482,6 +496,9 @@ attribute_container_class_device_del(struct device *classdev)
  *
  * Looks up the device in the container's list of class devices and returns
  * the corresponding class_device.
+ *
+ * Return: the matching class device, or NULL if the container has none
+ * for @dev.
  */
 struct device *
 attribute_container_find_class_device(struct attribute_container *cont,

---
base-commit: 5b0764a53235d3c77e1ed674e836e1b3fe1a4b1f
change-id: 20261024-kdoc-attrcont-d7d57b864032

Best regards,
-- 
Atanas Kunchev <atanaskunchev@proton.me>

