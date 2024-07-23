From: Joel Granados <j.granados@samsung.com>
Date: Tue, 23 Jul 2024 11:24:10 +0200
Subject: [PATCH b4] Forward the smtpserveroption to the local command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240723-master-v1-1-52a11f4a96c6@samsung.com>
X-B4-Tracking: v=1; b=H4sIALl2n2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDcyNj3dzE4pLUIl1Tw9TUNLNkA4MkwxQloOKCotS0zAqwQdFKSSZKsbW
 1AI7rm+xcAAAA
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.15-dev-02a2b
X-Developer-Signature: v=1; a=openpgp-sha256; l=1061;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=uG9WTIKIPuvqQDWXZefXFQZHYlIkkpS5tqQSEO+u3eY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGafdryHrWbyfumkJMkFwvkJ9HjzM6PrL7VY+
 CplRYRjTeeM34kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmn3a8AAoJELqXzVK3
 lkFPwjML/jBA/5apwQXJ/T3vW5ZUvV1F1n7ftH6w/07XixSQsST8S5mTnWNhCsmf90cCOIc9UHW
 AawEYGr2cQKV2TcU/I4YF65ksv8kwi2VL6hoxk8mtWrIbHuCVlQiiZ8oTuLH8zSU37o9TcCb+VL
 1vb9dw4Te4EhIfkolWJm6fl7AUwuf6sVJuTUG13tChYEI/bulj6Y9QmpbEvU9jPFPGMyuRfElta
 jsjhDUzvO1gRNtJBm3JVM2N7BDrZy4Y6P6mrghpIIFt4urJ6+RDu2xeDH12LANofUYuSeNZG426
 MmF0fflNYyV2ZcDBd+rI6kxOKdFk92Mra203/yj8J9QiP+IiVuLA7sxC/kl0Q1qBizbCgktqmlK
 nUBXHdLB7tdF0N3HBEpA74mZRt6XolrSbrvmCPRVs5OaqEDssHIW7N0fj+qhKA5d+z3q5PtMp0z
 Iq70bS4q/gQyKIcK4Px7BuCo2jocypTwx8kXGpxWSlkj3rWggn3CCZ3C4JB51G7z4in8yy0yo97
 JE=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Additional arguments to the smtp command are needed depending on the
sendemail identity. Append the additional arguments in smtpserveroptions
to the smtp command.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 src/b4/__init__.py | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/src/b4/__init__.py b/src/b4/__init__.py
index ae15b83..2b1a058 100644
--- a/src/b4/__init__.py
+++ b/src/b4/__init__.py
@@ -3783,6 +3783,9 @@ def get_smtp(dryrun: bool = False) -> Tuple[Union[smtplib.SMTP, smtplib.SMTP_SSL
                 envpair = email.utils.parseaddr(env_sender)
             if envpair[1]:
                 smtp += ['-f', envpair[1]]
+        server_option = sconfig.get('smtpserveroption', '')
+        if server_option:
+            smtp += [server_option]
         logger.debug('sendmail command: %s', ' '.join(smtp))
         return smtp, fromaddr
 

---
base-commit: a95708143ab35fe035ce852b72b94e68bbcb4f58
change-id: 20240723-master-51eef6c00b1d

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

