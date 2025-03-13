From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 13 Mar 2025 16:46:36 +0100
Subject: [PATCH] drop_caches: Allow re-enabling message after disabling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250313-jag-drop_caches_msg-v1-1-c2e4e7874b72@kernel.org>
X-B4-Tracking: v=1; b=H4sIANv90mcC/x3MTQqAIBBA4avErBM0a9NVIsKf0SZIxYEIorsnL
 b/Few8wVkKGuXug4kVMOTWovgO3mxRRkG+GQQ6T1EqLw0Thay6bM25H3k6Owo3BBvR2UkFDK0v
 FQPd/Xdb3/QD22YgqZQAAAA==
X-Change-ID: 20250313-jag-drop_caches_msg-c4fbfedb51f3
To: Jonathan Corbet <corbet@lwn.net>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, Ruiwu Chen <rwchen404@gmail.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1756;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=onqUyIR18v4Kxp915+i4qq8AG9pw2nIIaV6s1W5Ie2I=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfS/f6CEC4g2XnGlGRlSme4x3oOFMFovBpF7
 JcxYrJVTJTsb4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn0v3+AAoJELqXzVK3
 lkFPPNYL/jHTPUPVYZaSe0Tz1azPRYnf0WszSAKm+jNqgbZXptpqSIgTNuiRiXalABLa94PT/vf
 kNo26IgXSmsz7t/qRDUCSg6URaTItyfUMQ5kE12xtzqu4t6PBNRa0QfTcGG+ZkcQtD9k6iSx48u
 wWzjVc/l72eww/CtfGAvwGATdzt2jUxofWkUyPsXA9jYIs5staKiBzDPPgGhVWV3uUdXP+5xXws
 UxlT61ooON9PW0HVJds9DzHZz1/tO88Qgy5gs/kbheAPlL3sIIYxxyt/LwPyy9A8GrTZl/uSJv6
 OXIlkJ87Yt1cZBNYONFDiLdu+W8YJPmQpiGRZ+hGfAmJ/ExvRYCuZyz6CjtY+cc55YWjCCzRzdX
 IfaG1MM4FeDnkRVEjCRt5idGfM8rKxHfebqk4Z+HvAoqyPT8sBObxGl/r4Hu6ZvW4BLBUZfe6iy
 Y/BCsgAwQeMx4Df2x3fvD9rZpAYpFK5EB1VMx9/9znIOKAScp9HCqENAKc46/Sn6Jm8qAlyt0a7
 N0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After writing "4" to /proc/sys/vm/drop_caches there was no way to
re-enable the drop_caches kernel message. By removing the "or" logic for
the stfu variable in drop_cache_sysctl_handler, it is now possible to
toggle the message on and off by setting the 4th bit in
/proc/sys/vm/drop_caches.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 Documentation/admin-guide/sysctl/vm.rst | 2 +-
 fs/drop_caches.c                        | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/admin-guide/sysctl/vm.rst b/Documentation/admin-guide/sysctl/vm.rst
index f48eaa98d22d2b575f6e913f437b0d548daac3e6..75a032f8cbfb4e05f04610cca219d154bd852789 100644
--- a/Documentation/admin-guide/sysctl/vm.rst
+++ b/Documentation/admin-guide/sysctl/vm.rst
@@ -266,7 +266,7 @@ used::
 	cat (1234): drop_caches: 3
 
 These are informational only.  They do not mean that anything is wrong
-with your system.  To disable them, echo 4 (bit 2) into drop_caches.
+with your system.  To toggle them, echo 4 (bit 2) into drop_caches.
 
 enable_soft_offline
 ===================
diff --git a/fs/drop_caches.c b/fs/drop_caches.c
index d45ef541d848a73cbd19205e0111c2cab3b73617..501b9f690445e245f88cbb31a5123b2752e2e7ce 100644
--- a/fs/drop_caches.c
+++ b/fs/drop_caches.c
@@ -73,7 +73,7 @@ int drop_caches_sysctl_handler(const struct ctl_table *table, int write,
 				current->comm, task_pid_nr(current),
 				sysctl_drop_caches);
 		}
-		stfu |= sysctl_drop_caches & 4;
+		stfu = sysctl_drop_caches & 4;
 	}
 	return 0;
 }

---
base-commit: 7eb172143d5508b4da468ed59ee857c6e5e01da6
change-id: 20250313-jag-drop_caches_msg-c4fbfedb51f3

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

