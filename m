From: Jesse Van Gavere <jesse.vangavere@teledyne.com>
Date: Wed, 15 Jul 2026 15:52:23 +0200
Subject: [PATCH] overlayfs.rst: remove mention of workdir needing to be
 empty
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-overlayfs-rst-update-v1-1-70625a67880e@teledyne.com>
X-B4-Tracking: v=1; b=H4sIAJaQV2oC/yXMQQqDMBBA0avIrDsQA2m0VyldpGZSpxSVmSgW8
 e6NdvkW/2+gJEwKt2oDoYWVx6GgvlTQ9WF4EXIsBmvs1fja4biQfMI3KYpmnKcYMqF3JrrGtzb
 5Fko6CSVez+398bfOzzd1+XjBvv8Ag6T3KHgAAAA=
X-Change-ID: 20260715-overlayfs-rst-update-750d58792f79
To: Miklos Szeredi <miklos@szeredi.hu>, Amir Goldstein <amir73il@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-unionfs@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jesse Van Gavere <jesse.vangavere@teledyne.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784123559; l=1253;
 i=jesse.vangavere@teledyne.com; s=20260715; h=from:subject:message-id;
 bh=u9yuA8upX2scbp+cidGFdg1BSQtMNSI8cIdYLedjGX8=;
 b=qv4gFHFYbdGjveHk4GLTgLd/6es9PkHo7mg6Eot1a7EVHsS6F9+cDnr5lSdqpu5vGShJRwpQA
 OJflxTqoUmPCm574m3J/Odsy1db/6+kXKN12+iuf135IOnU5p05aUDD
X-Developer-Key: i=jesse.vangavere@teledyne.com; a=ed25519;
 pk=OyVy9LsOylefyENuukx/lDTq8X3QaHrhQKS3M67FQic=
X-Endpoint-Received: by B4 Relay for jesse.vangavere@teledyne.com/20260715 with auth_id=874
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This requirement has not been true since v4.8 when automatic cleanup was
added in commit eea2fb4851e9 ("ovl: proper cleanup of workdir")

Signed-off-by: Jesse Van Gavere <jesse.vangavere@teledyne.com>
---
 Documentation/filesystems/overlayfs.rst | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/filesystems/overlayfs.rst b/Documentation/filesystems/overlayfs.rst
index eb846518e6ac..7e28bfb4a99e 100644
--- a/Documentation/filesystems/overlayfs.rst
+++ b/Documentation/filesystems/overlayfs.rst
@@ -123,8 +123,8 @@ At mount time, the two directories given as mount options "lowerdir" and
   mount -t overlay overlay -olowerdir=/lower,upperdir=/upper,\
   workdir=/work /merged
 
-The "workdir" needs to be an empty directory on the same filesystem
-as upperdir.
+The "workdir" will be cleaned up at mount time and needs to be on the same
+filesystem as upperdir.
 
 Then whenever a lookup is requested in such a merged directory, the
 lookup is performed in each actual directory and the combined result

---
base-commit: 58717b2a1365d06c8c64b72aa948541b53fe31eb
change-id: 20260715-overlayfs-rst-update-750d58792f79

Best regards,
--  
Jesse Van Gavere <jesse.vangavere@teledyne.com>

