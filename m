From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 17 Jul 2024 18:26:45 +0100
Subject: [PATCH kmod] kmod: remove .alias config files for modprobe.d
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240717-rm-alias-v1-1-58874caf343a@gmail.com>
X-B4-Tracking: v=1; b=H4sIANT+l2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDcwML3aJc3cSczMRiXSMLCwND4zQLMxNTMyWg8oKi1LTMCrBR0bG1tQD
 XdGtoWgAAAA==
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721237206; l=1741;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=Gsv85/xQy8/nNNOgyhIvZ2Q6IxoNKQXq5wJxYihYbJA=;
 b=YWSsLvS2T0+cHnj8pSrWDmqPWICL4+EP3HJBG3pD69ws+jwtDZua0GvaSttJB9TQnPkwqDJN0
 FvWcCpspCteCdZ1VmOjaJF7dtFJPzDBnlPW0xuJQf42DNYYU5HXsJ5L
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The use of .alias (alongside .conf) was added for compatibility with the
original module-init-tools project and has been living in kmod ever
since.

In practise, all the linux distributions that I can see are using .conf
files alone, as instructed by modprobe.d(5) and the only instance of an
.alias file is the modules.alias as shipped in the kernel.

The latter is already handled by other parts of the kmod project, so
let's enforce what our documentation says.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
As suggested in https://lore.kernel.org/linux-modules/q6dutb2b5ztkuwjkq7a7ddnsbfneoq66bafaaxwppelepflcc5@us5n2ll5syja/T/#m84a542f8d4e2f4d31b2a7ee82aaf3d0bcf211aec

I have tested this on my Arch box, alongside a normal make
check/distcheck and it's working as expected. Other distributions have
not been tested, although I don't anticipate any to be using .alias
configuration files.

The section in the README will be removed shortly via unrelated patch.
---
 libkmod/libkmod-config.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/libkmod/libkmod-config.c b/libkmod/libkmod-config.c
index a571b6b..fb28ed9 100644
--- a/libkmod/libkmod-config.c
+++ b/libkmod/libkmod-config.c
@@ -940,8 +940,7 @@ static bool conf_files_filter_out(struct kmod_ctx *ctx, DIR *d,
 	if (fn[0] == '.')
 		return true;
 
-	if (len < 6 || (!streq(&fn[len - 5], ".conf")
-				&& !streq(&fn[len - 6], ".alias")))
+	if (len < 6 || !streq(&fn[len - 5], ".conf"))
 		return true;
 
 	fstatat(dirfd(d), fn, &st, 0);

---
base-commit: fa715f8c8b78a09f47701ce1cf46e9b67a49b8d0
change-id: 20240708-rm-alias-288013f86456

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

