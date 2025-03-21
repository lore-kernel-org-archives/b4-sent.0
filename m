From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH 0/4] sysctl: Move the u8 range check test to
 lib/test_sysctl.c
Date: Fri, 21 Mar 2025 13:47:23 +0100
Message-Id: <20250321-jag-test_extra_val-v1-0-a01b3b17dc66@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANtf3WcC/x3MQQqAIBBA0avErBNG06CuEhFDjTURFSoRRHdPW
 r7F/w9EDsIR2uKBwJdEOfYMXRYwLrTPrGTKBoPGYWW0WmlWiWMa+E6Bhos2ZbFxFh2S9jXk8Az
 s5f6nXf++H9WjZ5NkAAAA
X-Change-ID: 20250321-jag-test_extra_val-40954050a1f6
To: Kees Cook <kees@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 Shuah Khan <shuah@kernel.org>, John Sperbeck <jsperbeck@google.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1500;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=V1kuVirUzH2nkyWLPiJEMJZeSr0lXGHfzJy65bU2PIU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfdX/FPFhpvFqkJqN3iGTeATAeIgw8EUpiWc
 uFR+zMa2BVTtIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn3V/xAAoJELqXzVK3
 lkFPfJAL/RJDhNqBvDB4ZlliaKap+XBFny/pRlk5qJ+dvQS8sW+vmNPIciZJhg7giKcagOrfAAh
 GMnQ83x0sa2307sdt7pzOHKT0hHi0PxoJ+ifjT9fmNtZEgGixSV+ItF9woYnx8a4AZ3qs5ETsQZ
 EXPvLXPrt6RGQX2VtaietDAxKOmFQ7fj9KnXr5BS3rK4r5e12YJKo5yGs5kOa8fbrOXvIDKUcVN
 QHdq1YKZ8zfDE4UjxqScbUIQyWaxadehog7Jc3DPdB7WucQU8YyHCGTNp8CN82hBEYxvu3SRbYP
 x80/TXzWSa9Pf0nIMJnYGITm7im/p8GkA+Cbho+8JYyTUWj19/iTExtm8UGPwyV4vqpFX3ZcX5w
 UJxfpY8xqyjV2oJebrbraipCqvn5D3Ihk7naw9csbEeXAUTinsQl1cyLY4QspSxz8VHASkXqU9y
 bT6KSeP76eys4dqOsZB8/wCmPdMfYr7n4Eime7Kg6wLzprrzn9DxSqX077D1n+7/JjlYcXQ6AH5
 o0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Originally introduced to sysctl-test.c by commit b5ffbd139688 ("sysctl:
move the extra1/2 boundary check of u8 to sysctl_check_table_array"), it
has been shown to lead to a panic under certain conditions related to a
dangling registration.

This series moves the u8 test to lib/test_sysctl.c where the
registration calls are kept and correctly removed on module exit. An
additional 0012 test is added to selftests/sysctl/sysctl.sh in order to
visualize the registration calls done in test_sysctl.c.

Very much related to adding tests to sysctl, the last two patches of
this series reduce the places that need to be changed when tests are
added by managing the initialization and closing of sysctl tables with a
for loop.

Comments are greatly appreciated

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (4):
      sysctl: move u8 register test to lib/test_sysctl.c
      sysctl: Add 0012 to test the u8 range check
      sysctl: call sysctl tests with a for loop
      sysctl: Close test ctl_headers with a for loop

 kernel/sysctl-test.c                     |  49 ------------
 lib/test_sysctl.c                        | 133 +++++++++++++++++++++----------
 tools/testing/selftests/sysctl/sysctl.sh |  30 +++++++
 3 files changed, 122 insertions(+), 90 deletions(-)
---
base-commit: 7eb172143d5508b4da468ed59ee857c6e5e01da6
change-id: 20250321-jag-test_extra_val-40954050a1f6

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

