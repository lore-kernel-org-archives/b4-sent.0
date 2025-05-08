From: Chen Linxuan <chenlinxuan@uniontech.com>
Date: Thu, 08 May 2025 16:53:44 +0800
Subject: [PATCH v2 1/3] fs: fuse: add const qualifier to
 fuse_ctl_file_conn_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250508-fusectl-backing-files-v2-1-62f564e76984@uniontech.com>
References: <20250508-fusectl-backing-files-v2-0-62f564e76984@uniontech.com>
In-Reply-To: <20250508-fusectl-backing-files-v2-0-62f564e76984@uniontech.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Amir Goldstein <amir73il@gmail.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=867;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=5gsZgPpE9DdgJfjYJLZW01nMHgcjhblXor/5EfeOtfc=;
 b=kA0DAAoBdh7mFDmZrosByyZiAGgccSyhL2I1RGp5aE6Oi7v3yNvrXxNaW2mUx61V2VhZzF26t
 4kCMwQAAQoAHRYhBM7VUSUCTrF2/LRlWnYe5hQ5ma6LBQJoHHEsAAoJEHYe5hQ5ma6Llf4P+wVF
 AFOZayfsTWPOyAnfC7cM89rseJKs3NbylmfKz6jgD1QFtfs4pL4fZ9VN4wiz8Hv+ARcZ2gBr2O2
 XS4xIS9jTrZWFVMViuBWhAmsWoAH6IAopxPBWkqVTcwjUyrE2mupldzydmGZ0dgR1ugI6ErUsTb
 3OSouN+R0KAAaEey30IC9MXPCC9hfp6dD5mcg/KpNxa2TtItwyS3iXznFdmM/azcdXN8e8xjIpn
 z+litVFXZBw/z+dc+WHn9kqLFMBx78AXMvOZtMXbgdUr/POEduNJwvcf/QbKcn+kPy7IIK4PxIa
 gpzC+Ur6izsh+AuTwIoAdtadHuFVWXuJE3DPgnE680GSKy7voi4JvBqCV+M8Ppj7Nb8d1C/vG/c
 GoOTo6BicSToFD9PRasGtv7RQJyKKacKwarfD2rr4Y48IThLXOottiUnDs4Sy/322QmpldRVjn0
 sm1LrwzjTEHg2srN1J7qD1Cfyj0Nts/Br6lJb6kIOvQdtguoJucF7oY0vRPPiXM835gCwnee81p
 Q/+kMAIFsi+Mvq0cdDRtcGagrJfmHbU01Vew2/pOkLLik11yrr8ZIS3jryzUzfChwRdiSmOgPS7
 mRsTaWoNyyiC9peAlYF9f2WszTsbFTuDxrzvV6MiklM4KRO7CzfBSqt296oZWux+jyeeq8Cw2/V
 aQBIJ
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add const qualifier to the file parameter in fuse_ctl_file_conn_get
function to indicate that this function does not modify the passed file
object. This improves code clarity and type safety by making the API
contract more explicit.

Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
 fs/fuse/control.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/fuse/control.c b/fs/fuse/control.c
index 2a730d88cc3bdb50ea1f8a3185faad5f05fc6e74..f0874403b1f7c91571f38e4ae9f8cebe259f7dd1 100644
--- a/fs/fuse/control.c
+++ b/fs/fuse/control.c
@@ -20,7 +20,7 @@
  */
 static struct super_block *fuse_control_sb;
 
-static struct fuse_conn *fuse_ctl_file_conn_get(struct file *file)
+static struct fuse_conn *fuse_ctl_file_conn_get(const struct file *file)
 {
 	struct fuse_conn *fc;
 	mutex_lock(&fuse_mutex);

-- 
2.43.0

