From: Jesse Van Gavere <jesse.vangavere@teledyne.com>
Date: Thu, 16 Jul 2026 08:23:24 +0200
Subject: [PATCH v2] overlayfs.rst: remove mention of workdir needing to be
 empty
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-overlayfs-rst-update-v2-1-ba25393ea7a3@teledyne.com>
X-B4-Tracking: v=1; b=H4sIANt4WGoC/4WNQQ6CMBBFr2Jm7Zi2SSm48h6GRaWD1CAlndJIC
 HcX8AAuX/L++wswRU8M19MCkbJnH4YN1PkETWeHJ6F3G4MSqhBGagyZYm/nljFywml0NhEaLZw
 uTaVaU8E2HSO1/nNk7/WPeXq8qEl7azc6zynE+fjNcvf+XGSJEo0olLaFKUtBt0Q9uXmgSxPeU
 K/r+gWyHr0/zQAAAA==
X-Change-ID: 20260715-overlayfs-rst-update-750d58792f79
To: Miklos Szeredi <miklos@szeredi.hu>, Amir Goldstein <amir73il@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-unionfs@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jesse Van Gavere <jesse.vangavere@teledyne.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784183009; l=1682;
 i=jesse.vangavere@teledyne.com; s=20260715; h=from:subject:message-id;
 bh=cFSfchcWu1ZV/AY69ZArDpiRNyf4mv59SjB1KVkBfnQ=;
 b=TnPAganZkbhxTg0lEDSqsIwbKPHsjAkH9xslf2RsaYF6CRC2TaOznye2mzsaG458syCvjzVbN
 JdC+GOhyuKlB8VCVbz95A6xytbaAy1grE3Er8l4tKOoQiq8j1c/YdDo
X-Developer-Key: i=jesse.vangavere@teledyne.com; a=ed25519;
 pk=OyVy9LsOylefyENuukx/lDTq8X3QaHrhQKS3M67FQic=
X-Endpoint-Received: by B4 Relay for jesse.vangavere@teledyne.com/20260715 with auth_id=874
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This requirement has not been true since v4.8 when automatic cleanup was
added in commit eea2fb4851e9 ("ovl: proper cleanup of workdir")

Signed-off-by: Jesse Van Gavere <jesse.vangavere@teledyne.com>
---
Changes in v2:
- Handle remark from Amir Goldstein to drop workdir cleanup reference
- Link to v1: https://patch.msgid.link/20260715-overlayfs-rst-update-v1-1-70625a67880e@teledyne.com

To: Miklos Szeredi <miklos@szeredi.hu>
To: Amir Goldstein <amir73il@gmail.com>
To: Jonathan Corbet <corbet@lwn.net>
To: Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-unionfs@vger.kernel.org
Cc: linux-doc@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 Documentation/filesystems/overlayfs.rst | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/Documentation/filesystems/overlayfs.rst b/Documentation/filesystems/overlayfs.rst
index eb846518e6ac..ba41c0694e62 100644
--- a/Documentation/filesystems/overlayfs.rst
+++ b/Documentation/filesystems/overlayfs.rst
@@ -123,8 +123,7 @@ At mount time, the two directories given as mount options "lowerdir" and
   mount -t overlay overlay -olowerdir=/lower,upperdir=/upper,\
   workdir=/work /merged
 
-The "workdir" needs to be an empty directory on the same filesystem
-as upperdir.
+The "workdir" needs to be a directory on the same filesystem as upperdir.
 
 Then whenever a lookup is requested in such a merged directory, the
 lookup is performed in each actual directory and the combined result

---
base-commit: 58717b2a1365d06c8c64b72aa948541b53fe31eb
change-id: 20260715-overlayfs-rst-update-750d58792f79

Best regards,
--  
Jesse Van Gavere <jesse.vangavere@teledyne.com>

