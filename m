From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Sat, 17 Aug 2024 10:00:53 +0200
Subject: [PATCH b4] Document patatt key selector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240817-selector-doc-v1-1-7c5c824a4e9d@skole.hr>
X-B4-Tracking: v=1; b=H4sIALVYwGYC/x3MQQqAIBBA0avErBNUjLSrRIvSsQZCQyMC8e5Jy
 7f4v0DGRJhh6gokfChTDA2i78Aea9iRkWsGyaXiWows44n2jom5aBkqboRWRg5eQ0uuhJ7efzf
 DpmCp9QNRSBWzYgAAAA==
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1791;
 i=duje.mihanovic@skole.hr; s=20240706; h=from:subject:message-id;
 bh=1wfqlisqcIHFWOChgds5FzvapQFDMUC8CZXJftubi1c=;
 b=owGbwMvMwCW21nBykGv/WmbG02pJDGkHInZdv1LU1p2n/SX0yuF21lBG1g3KjouWMFiuPvGwX
 rncuv9BRykLgxgXg6yYIkvuf8drvJ9Ftm7PXmYAM4eVCWQIAxenAEykp5Phv5vDyRvvZ/40/vtB
 TSTx/rY9K79FGX9cxHtdTSisL0f5uj0jw+NfftyfhOKCvYWPvfupX2QvPLdhZ9waxvBN15aduLZ
 YnwMA
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=6DFF41D60DF314B5B76BA630AD319352458FAD03
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/20240706 with auth_id=191
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This selector can be used to authorize multiple keys for one email
address, but hasn't been documented anywhere as far as I can tell.

Link: https://lore.kernel.org/all/20240729-macaque-of-inspiring-recreation-9e5c4b@lemur/
Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
 docs/contributor/send.rst | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/docs/contributor/send.rst b/docs/contributor/send.rst
index a597ac5..54ed474 100644
--- a/docs/contributor/send.rst
+++ b/docs/contributor/send.rst
@@ -122,6 +122,23 @@ from the message::
 
 You should now be able to send patches via this web submission endpoint.
 
+Changing your attestation key
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+If you change your attestation key without changing your email address (e.g.
+switch from a ``patatt`` generated key to a PGP key or change your PGP keys),
+your previous authorization will stop working. Trying to reauthorize will also
+result in an error as changing the attestation key is `currently unsupported
+<https://lore.kernel.org/tools/4608818.LvFx2qVVIh@radijator/T/#m9aa19999463864341ed8be929f470e5439513256>`_.
+Instead, you can change the key selector to something other than ``default``
+with the following setting::
+
+    [patatt]
+       selector = something
+
+.. note::
+   The selector can be anything besides default or any previously used selector.
+   For example, you could use the creation date of your PGP key.
+
 Using your own SMTP server
 --------------------------
 If there is a ``sendmail`` section in your git configuration, B4 tries

---
base-commit: 37811c93f50e70f325e45107a9a20ffc69f2f6dc
change-id: 20240817-selector-doc-e409184925f8

Best regards,
-- 
Duje Mihanović <duje.mihanovic@skole.hr>

