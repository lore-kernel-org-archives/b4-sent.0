From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 29 Nov 2024 20:42:29 +0100
Subject: [PATCH 2/2] doc: sending_patches: Fix spelling of "its"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241129-typo-v1-2-1ac3fef74eee@posteo.net>
References: <20241129-typo-v1-0-1ac3fef74eee@posteo.net>
In-Reply-To: <20241129-typo-v1-0-1ac3fef74eee@posteo.net>
To: Mario Six <mario.six@gdsys.cc>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732909355; l=910;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=NllmgewEy4nTBlFIvFRSMaSbrEZOxfKQ4ss3cfPTC7M=;
 b=uXNcpgdBHVzhYag0ONfx97vxOfolQihBOU9NuWId0wdJRZTbM+BnlK4panFKd7Y62j77Cf/IH
 ALsR4934vWqC6stO9w1slVPflUga7CKkbhLhusGhYSgqANUflVs9qbT
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Although it has historically been different, the current standard
spelling of the neutral singular possessive pronoun is "its".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 doc/develop/sending_patches.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/doc/develop/sending_patches.rst b/doc/develop/sending_patches.rst
index e22b5e3e244eac9f7e451781a380caba93f2ab17..ee6e34089b5b24b01b0ad30e142f80ae4a356089 100644
--- a/doc/develop/sending_patches.rst
+++ b/doc/develop/sending_patches.rst
@@ -377,7 +377,7 @@ The following are a "rule of thumb" as to how the states are used in patchwork
 today. Not all states are used by all custodians.
 
 * New: Patch has been submitted to the list, and none of the maintainers has
-  changed it's state since.
+  changed its state since.
 
 * Under Review: A custodian is reviewing the patch currently.
 

-- 
2.45.2

