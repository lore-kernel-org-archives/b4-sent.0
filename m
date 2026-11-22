From: Vencislav Atanasov <user890104@freemyipod.org>
Date: Sun, 22 Nov 2026 23:00:11 +0200
Subject: [PATCH v2] doc: Add section about mail providers which modify
 Message-ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-doc-msgid-v2-1-10c717d50d1f@freemyipod.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NywqDMBBFf0Vm3ZSMrQ+68j+Ki2gmOgWNJFYqk
 n9vYrflrg4czj3Ak2Py8MgOcLSxZztHyC8Z9KOaBxKsI0Mu8xIRa6FtLyY/sBb6RoW6FygrVBD
 9xZHhz9l6tj/27+5F/ZoCyRjZr9bt59mGyfvX3VDEybruTCnRdFVjHNG082L11boB2hDCF1SuU
 Oi5AAAA
X-Change-ID: 20261118-doc-msgid-d3e5a451071a
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Vencislav Atanasov <user890104@freemyipod.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795381222; l=2176;
 i=user890104@freemyipod.org; s=20261004; h=from:subject:message-id;
 bh=fmz+T9rLiN6nMaBX6pIg1i9TxswslFkT3LQYtgKgKWg=;
 b=01j2RROdROSZSOB7OlwOAvBgkobSvX/JUr1eYqxITXfqDgXWzXisXYEULN2jwEvClf4l7uLuV
 tt3rscQB/JqDp7HkKKw1455sjM5f13wkX8CQMq1m9VjcFUS0zRSCrae
X-Developer-Key: i=user890104@freemyipod.org; a=ed25519;
 pk=klj5EgxMkX+YF0tPboUEB9kwBfthBgHWLhDOkwnmUus=
X-Endpoint-Received: by B4 Relay for user890104@freemyipod.org/20261004 with auth_id=1558
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A short debugging session revealed that AWS SES completely replaces
the Message-ID header, even though the API is called SendRawEmail.

Signed-off-by: Vencislav Atanasov <user890104@freemyipod.org>
---
Changes in v2:
- Reworded the paragraph
- Used a different link to b4 docs
- Link to v1: https://patch.msgid.link/20261118-doc-msgid-v1-1-1088bf601fb7@freemyipod.org

To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>
Cc: Quentin Schulz <quentin.schulz@cherry.de>
Cc: Mattijs Korpershoek <mkorpershoek@kernel.org>
Cc: Neil Armstrong <neil.armstrong@linaro.org>
---
 doc/develop/sending_patches.rst | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/doc/develop/sending_patches.rst b/doc/develop/sending_patches.rst
index 99581dc0ba0..027e7be028a 100644
--- a/doc/develop/sending_patches.rst
+++ b/doc/develop/sending_patches.rst
@@ -184,6 +184,20 @@ General Patch Submission Rules
   cases, you did something wrong if your patch exceeds this limit. Think again
   if you should not split it into separate logical parts.
 
+* If sending patches through your mail server is broken, doesn't work at all or
+  is not possible, consider using `b4's web endpoint <b4-web-endpoint-link_>`_.
+  It will allow you to send patches without using your mail server. A notable
+  example is `Amazon Web Services' Simple E-mail Service (AWS SES)
+  <aws-ses-sendrawemail-message-id-link_>`_. It modifies the Message-ID header
+  and your individual patches don't point back to the cover letter and vice
+  versa.
+
+.. _aws-ses-sendrawemail-message-id-link:
+   https://docs.aws.amazon.com/ses/latest/APIReference/API_SendRawEmail.html#:~:text=Amazon%20SES%20automatically%20applies%20its%20own%20Message%2DID
+
+.. _b4-web-endpoint-link:
+   https://b4.docs.kernel.org/en/latest/contributor/send.html#authenticating-with-the-web-submission-endpoint
+
 Attributing Code, Copyrights, Signing
 -------------------------------------
 

---
base-commit: 2f83ef8a7dd4a409b534ea68cd13b17b686cc53c
change-id: 20261118-doc-msgid-d3e5a451071a

Best regards,
--  
Vencislav Atanasov <user890104@freemyipod.org>

