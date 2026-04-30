From: Alireza Haghdoost <haghdoost@uber.com>
Date: Thu, 30 Apr 2026 22:52:53 +0000
Subject: [PATCH] checkpatch: recognize the Assisted-by: trailer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260430-fix-checkpatch-assisted-by-v1-1-46d3ef68a1de@uber.com>
X-B4-Tracking: v=1; b=H4sIAETd82kC/x2NQQrCQAxFr1KyNjCtVtSriItMJnWCOJZJEUvp3
 Zu6fLzP+wuYVBWDW7NAla+afopDe2iAM5WnoCZn6EJ3DqdjwEF/yFn4NdLEGclMbZKEccaL9Ne
 hFwqcWvBAJBOMlQrnPfEmH9ZdjFU883+9P9Z1A463cSaFAAAA
To: Andy Whitcroft <apw@canonical.com>, Joe Perches <joe@perches.com>, 
 Dwaipayan Ray <dwaipayanray1@gmail.com>, 
 Lukas Bulwahn <lukas.bulwahn@gmail.com>
Cc: linux-kernel@vger.kernel.org, Alireza Haghdoost <haghdoost@uber.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3855; i=haghdoost@uber.com;
 h=from:subject:message-id; bh=1L/K7YExDBD3NfbBSUkBDm0Ajzp1G2Obp39ZJ72g7eA=;
 b=owEBbQKS/ZANAwAKAVNlBDxl2ALYAcsmYgBp891RZReFtwOsixLJxYkesTWsqVMS87Nhh4/4I
 tECZCcIo5+JAjMEAAEKAB0WIQS5+sFL3gX/8PrA0S1TZQQ8ZdgC2AUCafPdUQAKCRBTZQQ8ZdgC
 2F6FD/0b91gYN3TXa7oA8ym71E7i6/GIo05VSmrE4BlVFu1sL2MsjoR6bAX7uDcWY3jbfWSmHfu
 wJodNeNbtLEAoDtq7woGEABLYA0001icm2g6/Xh7QaZQwAYHxrMyoih7ERZRQrCI62ZnVoAxBa8
 dVkb0YtpCf3A4JcjuBC6q9Ci4YmJ7aQEM3RJAK+qp0ttz3BPoCcEO34Z4dPsZMAGrlTo2HHKDPA
 y5uX8zlfWRtNtnHpS16XzOIEaEndKxckZlNUm+Pd2Nz6e54/oDLipH6rjMxdkjIqpXtgqDDMPy0
 uH27ZAPRA+mOQ0uWlqvyQ5UTe1DZDTvrIRX1B9rh88u+N5EawyaZDWAQh9pp8YbC0Anqb5NWjpE
 XEe5V3/E82zPP6AzSV4MoKl31gS3g2sP8ZukBKrXThn5uvnh2kdWbNQIFDDFTFCZym266tH0xwV
 5Ut3Dy/hWh/DkAyBE7j7WORR3G3cwIgqQwJBcAJlXWb0waVuTPQWccV6wumStKK/sYuMqe7CfYq
 Kwg93FFxLNI/dzfCl4xCUzf9DkAdsW2wF2Ph428VnZK7ll3Wzm307hykl4BkAkIL21SEOW1bhnk
 vhkvWicpFzdmLXfS1oNy2KMCWr7/bQiqMzA6GXSO5/qwZLbx8Ely2LLTQeRRP9vfJmGliY8WRbd
 8he4nmayIekDUWw==
X-Developer-Key: i=haghdoost@uber.com; a=openpgp;
 fpr=B9FAC14BDE05FFF0FAC0D12D5365043C65D802D8
X-Endpoint-Received: by B4 Relay for haghdoost@uber.com/default with auth_id=764
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Documentation/process/coding-assistants.rst, added in commit
78d979db6cef ("docs: add AI Coding Assistants documentation"),
mandates an Assisted-by trailer for any patch developed with help
from an AI coding assistant. The documented format is
"Assisted-by: AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2]" (for example,
"Assisted-by: Claude:claude-3-opus coccinelle sparse").

scripts/checkpatch.pl was not updated alongside the documentation.
The trailer name matches the script's generic [a-z0-9_-]+by: pattern,
so checkpatch (a) emits a "Non-standard signature: Assisted-by:"
WARNING because Assisted-by: is absent from $signature_tags, and
(b) emits an "Unrecognized email address" ERROR because the value
is not an RFC 5322 email but the AGENT_NAME:MODEL_VERSION form
prescribed by the spec. Both fire on every correctly-formed
Assisted-by: tag, making it impossible to satisfy both the
documentation and checkpatch at the same time.

Add Assisted-by: to $signature_tags and to the @standard_signature_tags
list (so suggested-typo correction works for it). Introduce a new
$no_email_signature_tags pattern listing trailers that, by spec, do
not carry an email address, and gate the email parse / format / stable
address checks on it; today only Assisted-by: is in that list, but the
mechanism is general for future tags with similar conventions.

A regression test confirms a malformed sign-off line still triggers
the "Unrecognized email address" ERROR after this change, since
Signed-off-by is not in $no_email_signature_tags.

Signed-off-by: Alireza Haghdoost <haghdoost@uber.com>
Assisted-by: Cursor:claude-sonnet-4.5
---
Single patch. The commit message contains the full rationale and
a description of the mechanism. No cover needed beyond what is there.
---
 scripts/checkpatch.pl | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/scripts/checkpatch.pl b/scripts/checkpatch.pl
index e56374662ff7..a9ebb67686ea 100755
--- a/scripts/checkpatch.pl
+++ b/scripts/checkpatch.pl
@@ -641,10 +641,19 @@ our $signature_tags = qr{(?xi:
 	Reviewed-by:|
 	Reported-by:|
 	Suggested-by:|
+	Assisted-by:|
 	To:|
 	Cc:
 )};
 
+# Trailers that do not carry an RFC 5322 email address.
+# Documentation/process/coding-assistants.rst defines Assisted-by: as
+# carrying "AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2]" rather than an
+# email address; skip the email-format checks for these tags.
+our $no_email_signature_tags = qr{(?xi:
+	Assisted-by:
+)};
+
 our @link_tags = qw(Link Closes);
 
 #Create a search and print patterns for all these strings to be used directly below
@@ -737,7 +746,7 @@ sub find_standard_signature {
 	my ($sign_off) = @_;
 	my @standard_signature_tags = (
 		'Signed-off-by:', 'Co-developed-by:', 'Acked-by:', 'Tested-by:',
-		'Reviewed-by:', 'Reported-by:', 'Suggested-by:'
+		'Reviewed-by:', 'Reported-by:', 'Suggested-by:', 'Assisted-by:'
 	);
 	foreach my $signature (@standard_signature_tags) {
 		return $signature if (get_edit_distance($sign_off, $signature) <= 2);
@@ -3105,6 +3114,9 @@ sub process {
 				}
 			}
 
+			# Skip email-format checks for trailers that, by spec, do
+			# not carry an email address (e.g. Assisted-by:).
+			if ($sign_off !~ /$no_email_signature_tags/) {
 			my ($email_name, $name_comment, $email_address, $comment) = parse_email($email);
 			my $suggested_email = format_email(($email_name, $name_comment, $email_address, $comment));
 			if ($suggested_email eq "") {
@@ -3189,6 +3201,7 @@ sub process {
 					}
 				}
 			}
+			}
 
 # Check for duplicate signatures
 			my $sig_nospace = $line;

---
base-commit: 46b513250491a7bfc97d98791dbe6a10bcc8129d
change-id: 20260430-fix-checkpatch-assisted-by-8e59f5ea0cd1

Best regards,
-- 
Alireza Haghdoost <haghdoost@uber.com>

