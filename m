From: Martin Belanger <martin.nvme.dev@gmail.com>
Date: Wed, 14 Oct 2026 08:02:57 -0400
Subject: [PATCH v2] nvme: make the DH-HMAC-CHAP secret attributes readable
 by root only
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-nvme-dhchap-secret-mode-v2-1-00f153e9d8de@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQqDMBCE4avIPruQBBXbqxQf0mRat2CUrJWCe
 Pem9vFjmH8nRRYoXaudMjZRmVOBqysKo09PsMRicsZ11tiG0zaB41jGhRUhY+VpjuCLNT36trG
 +81TeS8ZDPmf5Nvyt7/sLYf3l6Di+N1PvwnsAAAA=
X-Change-ID: 20261014-nvme-dhchap-secret-mode-9108e8541a6a
To: linux-nvme@lists.infradead.org
Cc: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@suse.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daniel Wagner <wagi@kernel.org>, 
 Martin Belanger <martin.nvme.dev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791979381; l=3245;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=YzbJwanbX41Lark5YtJVe0AVHqjgNwPQp5aKXMjqULc=;
 b=Ib1ZrDnxDTZUZttiA/j38dYPB1shdfmMLlyzRHHYeQXx39wMBm0oCvjyCGsOWT6Pg9LxNjdEe
 BPQOfx/SYBSBcZ9lScWoyTQiBHjNkklIXz+JidH/a/XcYrQTafeCu+O
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dhchap_secret and dhchap_ctrl_secret sysfs attributes have mode
0644. Their show functions return the secret, so any local user can
read the DH-HMAC-CHAP secrets of a connected controller.

Define them with DEVICE_ATTR_ADMIN_RW(), which sets mode 0600. The
macro takes the show and store functions from the attribute name, so
rename them. Writing the attributes was already limited to root and is
not changed.

Fixes: f50fff73d620 ("nvme: implement In-Band authentication")
Cc: stable@vger.kernel.org
Cc: Daniel Wagner <wagi@kernel.org>
Assisted-by: LLM
Signed-off-by: Martin Belanger <martin.nvme.dev@gmail.com>
---
Changes in v2:
- Use DEVICE_ATTR_ADMIN_RW() instead of DEVICE_ATTR() with 0600 (Greg)
---
 drivers/nvme/host/sysfs.c | 14 ++++++--------
 1 file changed, 6 insertions(+), 8 deletions(-)

diff --git a/drivers/nvme/host/sysfs.c b/drivers/nvme/host/sysfs.c
index e1e3dcfd084b..c0ecb5df1a30 100644
--- a/drivers/nvme/host/sysfs.c
+++ b/drivers/nvme/host/sysfs.c
@@ -809,7 +809,7 @@ static DEVICE_ATTR(io_timeout, S_IRUGO | S_IWUSR,
 	nvme_io_timeout_show, nvme_io_timeout_store);
 
 #ifdef CONFIG_NVME_HOST_AUTH
-static ssize_t nvme_ctrl_dhchap_secret_show(struct device *dev,
+static ssize_t dhchap_secret_show(struct device *dev,
 		struct device_attribute *attr, char *buf)
 {
 	struct nvme_ctrl *ctrl = dev_get_drvdata(dev);
@@ -820,7 +820,7 @@ static ssize_t nvme_ctrl_dhchap_secret_show(struct device *dev,
 	return sysfs_emit(buf, "%s\n", opts->dhchap_secret);
 }
 
-static ssize_t nvme_ctrl_dhchap_secret_store(struct device *dev,
+static ssize_t dhchap_secret_store(struct device *dev,
 		struct device_attribute *attr, const char *buf, size_t count)
 {
 	struct nvme_ctrl *ctrl = dev_get_drvdata(dev);
@@ -864,10 +864,9 @@ static ssize_t nvme_ctrl_dhchap_secret_store(struct device *dev,
 	return count;
 }
 
-static DEVICE_ATTR(dhchap_secret, S_IRUGO | S_IWUSR,
-	nvme_ctrl_dhchap_secret_show, nvme_ctrl_dhchap_secret_store);
+static DEVICE_ATTR_ADMIN_RW(dhchap_secret);
 
-static ssize_t nvme_ctrl_dhchap_ctrl_secret_show(struct device *dev,
+static ssize_t dhchap_ctrl_secret_show(struct device *dev,
 		struct device_attribute *attr, char *buf)
 {
 	struct nvme_ctrl *ctrl = dev_get_drvdata(dev);
@@ -878,7 +877,7 @@ static ssize_t nvme_ctrl_dhchap_ctrl_secret_show(struct device *dev,
 	return sysfs_emit(buf, "%s\n", opts->dhchap_ctrl_secret);
 }
 
-static ssize_t nvme_ctrl_dhchap_ctrl_secret_store(struct device *dev,
+static ssize_t dhchap_ctrl_secret_store(struct device *dev,
 		struct device_attribute *attr, const char *buf, size_t count)
 {
 	struct nvme_ctrl *ctrl = dev_get_drvdata(dev);
@@ -922,8 +921,7 @@ static ssize_t nvme_ctrl_dhchap_ctrl_secret_store(struct device *dev,
 	return count;
 }
 
-static DEVICE_ATTR(dhchap_ctrl_secret, S_IRUGO | S_IWUSR,
-	nvme_ctrl_dhchap_ctrl_secret_show, nvme_ctrl_dhchap_ctrl_secret_store);
+static DEVICE_ATTR_ADMIN_RW(dhchap_ctrl_secret);
 #endif
 
 static struct attribute *nvme_dev_attrs[] = {

---
base-commit: 24a19b953e2a3d0ea5a8c4951a0ab8f32720c907
change-id: 20261014-nvme-dhchap-secret-mode-9108e8541a6a

Best regards,
--  
Martin Belanger <martin.nvme.dev@gmail.com>

