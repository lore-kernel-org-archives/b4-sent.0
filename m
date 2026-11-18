From: Vencislav Atanasov <user890104@freemyipod.org>
Date: Wed, 18 Nov 2026 17:46:20 +0200
Subject: [PATCH] doc: Add section about mail providers which modify
 Message-ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-doc-msgid-v1-1-1088bf601fb7@freemyipod.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM2wpAQBCA4VfRXNsyznkVuVi7g1EO7SAl725x+
 dXff4GQYxKoggscHSy8zB4YBmAGPfek2HpDHMU5IpbKLkZN0rNVNqFMpxlGBWrw/eqo4/N71c1
 v2duRzPYO4L4fLFu1aW0AAAA=
X-Change-ID: 20261118-doc-msgid-d3e5a451071a
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Vencislav Atanasov <user890104@freemyipod.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795016798; l=1716;
 i=user890104@freemyipod.org; s=20261004; h=from:subject:message-id;
 bh=twFzVjuC/wrq/GFDc43jLfsEY6afcqFJXJ+Jjg8YETc=;
 b=0qXI3Mv1XCkPtsIXJGfDGslrjtxpJjqIc19EtmM0jT1AfHfT1rAkoupZr+Y3530gP97m7pvid
 oVeSvUCjdGgCVO7a3oTivotp1bNfdWa83f4tdpBmBD5idoy5EYh8ql7
X-Developer-Key: i=user890104@freemyipod.org; a=ed25519;
 pk=klj5EgxMkX+YF0tPboUEB9kwBfthBgHWLhDOkwnmUus=
X-Endpoint-Received: by B4 Relay for user890104@freemyipod.org/20261004 with auth_id=1558
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A short debugging session revealed that AWS SES completely replaces
the Message-ID header, even though the API is called SendRawEmail.

Signed-off-by: Vencislav Atanasov <user890104@freemyipod.org>
---
 doc/develop/sending_patches.rst | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/doc/develop/sending_patches.rst b/doc/develop/sending_patches.rst
index 99581dc0ba0..e2d5e4b15c2 100644
--- a/doc/develop/sending_patches.rst
+++ b/doc/develop/sending_patches.rst
@@ -184,6 +184,19 @@ General Patch Submission Rules
   cases, you did something wrong if your patch exceeds this limit. Think again
   if you should not split it into separate logical parts.
 
+* If you use a mail service which modifies the Message-ID header, your
+  individual patches won't point back to the cover letter and vice versa. A
+  notable example is `Amazon Web Services' Simple E-mail Service (AWS SES)
+  <aws-ses-sendrawemail-message-id-link_>`_.
+  In this case, you can use the Web endpoint of kernel.org's B4 Relay. See the
+  `b4 documentation <b4-web-endpoint-link_>`_ for setup and usage instructions.
+
+.. _aws-ses-sendrawemail-message-id-link:
+   https://docs.aws.amazon.com/ses/latest/APIReference/API_SendRawEmail.html#:~:text=Amazon%20SES%20automatically%20applies%20its%20own%20Message%2DID
+
+.. _b4-web-endpoint-link:
+   https://b4.docs.kernel.org/en/latest/contributor/send.html#configuring-the-web-endpoint
+
 Attributing Code, Copyrights, Signing
 -------------------------------------
 

---
base-commit: 2f83ef8a7dd4a409b534ea68cd13b17b686cc53c
change-id: 20261118-doc-msgid-d3e5a451071a

Best regards,
--  
Vencislav Atanasov <user890104@freemyipod.org>

