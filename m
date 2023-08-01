From: Joel Granados <j.granados@samsung.com>
Date: Tue, 01 Aug 2023 17:03:36 +0200
Subject: [PATCH b4] ez: Add a --web arg to force web endpoint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230801-jag-add_web_switch-v1-1-a0021c1ee8c2@samsung.com>
X-B4-Tracking: v=1; b=H4sIAMceyWQC/x3MQQqAIBBA0avErBNskpKuEiGWU02LCo0MpLsnL
 d/i/wSBPFOArkjg6ebAx55RlQVMq90XEuyyASXWUstKbHYR1jkTaTQh8jWtQqFVqNu20eQgh6e
 nmZ9/2sOoYHjfD1ogo5RoAAAA
To: "Kernel.org Tools" <tools@linux.kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-8c87d
X-Developer-Signature: v=1; a=openpgp-sha256; l=3466;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=h27KrWtIi1eIyqHt0+SkV95x7OnyS4fVmHaeCUXDJfk=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBkyR7U8pJGV5L9obxlUVTOB30y1+47NtimxBbL5
 pg0ek+NwiSJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZMke1AAKCRC6l81St5ZB
 TzQ/C/9vKrxsGl9dDowgSpGl35TkC23EngAdapv5ONucZQc5uLGmHXaRpxKXEHNXdbe7YxOAbcP
 Hme6+38RfcA71ThwS6EHhF0VD/lFBYYQbFBKzbp9SqKrNSErbDk0G1ZM2smO7UXmnIQR/Sn859w
 VWjXoE6RbDrIEmnaKVHjdMIL1saSKdx1gVZ76UUJb9JINWfudTFzxcsBNnOORnihUPCwkPGa39q
 K1o7/G7BJu6d/kzpPAXhacRi4LR3Z4gklNpqzMVvkvXmBoS/WdJx11XLuvBgkf3Y5gYWNHMyxcA
 ttcnDx1zJ1wDcOyqyvSs+o2wG3AeOP2kWT8S3trzsT28AAllMOjJwaMcZgYRRejhbh1d1p2NrPa
 1282fBgRcw3+F7WyiJaAUMcjnp/dmThARVvEXKeEFw0BfZu36ZJTR1rP+VmY+m90Ixdv0C9X5/j
 6B3u62a5oKw0FJCJU2kDE0ryIsUGIvled7qw6vZS+z0k+M2T+bo5IJq5DtLShNQxFxQLA=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make it easier to prefer going through the web endpoint by adding an
argument that will force this path. This is for users that want to use
B4 for preparing and sharing patchsets over mail and need an argument to
activate the web endpoint whenever needed, but want to default to smtp
server for the rest.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 b4/command.py             |  2 ++
 b4/ez.py                  |  4 +---
 docs/contributor/send.rst | 10 ++++++----
 3 files changed, 9 insertions(+), 7 deletions(-)

diff --git a/b4/command.py b/b4/command.py
index 1ae73d2..15ca370 100644
--- a/b4/command.py
+++ b/b4/command.py
@@ -330,6 +330,8 @@ def setup_parser() -> argparse.ArgumentParser:
                           help='Initiate a new web authentication request')
     ag_sendh.add_argument('--web-auth-verify', dest='auth_verify', metavar='VERIFY_TOKEN',
                           help='Submit the token received via verification email')
+    ag_sendh.add_argument('--web', dest='send_web', action='store_true', default=False,
+                          help="Force the send command to go through the web endpoint")
     sp_send.set_defaults(func=cmd_send)
 
     return parser
diff --git a/b4/ez.py b/b4/ez.py
index 3799e07..e38827f 100644
--- a/b4/ez.py
+++ b/b4/ez.py
@@ -1459,10 +1459,8 @@ def cmd_send(cmdargs: argparse.Namespace) -> None:
         pathlib.Path(cmdargs.output_dir).mkdir(parents=True, exist_ok=True)
 
     sconfig = b4.get_sendemail_config()
-    # If we have an smtp server defined, always use that instead of the endpoint
-    # we may make this configurable in the future, but this almost always makes sense
     endpoint = None
-    if not sconfig.get('smtpserver'):
+    if not sconfig.get('smtpserver') or cmdargs.send_web:
         endpoint = config.get('send-endpoint-web', '')
         if not re.search(r'^https?://', endpoint):
             logger.debug('Endpoint does not start with https, ignoring: %s', endpoint)
diff --git a/docs/contributor/send.rst b/docs/contributor/send.rst
index 9be8d1c..ca7f082 100644
--- a/docs/contributor/send.rst
+++ b/docs/contributor/send.rst
@@ -124,9 +124,10 @@ You should now be able to send patches via this web submission endpoint.
 
 Using your own SMTP server
 --------------------------
-B4 will use the ``sendemail`` section from your git configuration, but
-it only supports the most common subset of options. The vast majority of
-servers will only need the following settings::
+If there is a ``sendmail`` section in your git configuration, B4 will try use
+that by default instead of the web endpoint. Only the most common subset of
+options are supported. The vast majority of servers will only need the
+following settings::
 
     [sendemail]
        smtpServer = smtp.example.org
@@ -136,7 +137,8 @@ servers will only need the following settings::
        smtpPass = [omitted]
 
 You can also set up msmtp or a similar tool and specify the path to the
-``sendmail``-compliant binary as the value for ``smtpServer``.
+``sendmail``-compliant binary as the value for ``smtpServer``. You can force B4
+to use the web endpoint by passing ``--web`` to the send command.
 
 Sending your patches
 --------------------

---
base-commit: 099c9b47b39b6076752b8c757872080fad8fae56
change-id: 20230801-jag-add_web_switch-42a4287768ed

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

