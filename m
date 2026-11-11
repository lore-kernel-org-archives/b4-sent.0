From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/2] landlock: Fix landlock_restrict_self() on long
 executable paths
Date: Wed, 11 Nov 2026 13:54:45 +0900
Message-Id: <20261111-landlock-long-exe-v1-0-588cfd174a10@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABX182oC/x3MQQqAIBBA0avErBtwFFp0lWiROtWQaCiEEN49a
 fkW/79QOAsXmIcXMj9SJMUOGgdw5xYPRvHdoJWeiEhh2KIPyV0YUjyQK+NEztrdOmOUgt7dmXe
 p/3NZW/sAA1FTl2MAAAA=
To: =?utf-8?q?Micka=C3=ABl_Sala=C3=BCn?= <mic@digikod.net>, 
 =?utf-8?q?G=C3=BCnther_Noack?= <gnoack@google.com>
Cc: Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>, Shuah Khan <shuah@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Dwi Siswanto <me@dw1.io>, 
 =?utf-8?q?G=C3=BCnther_Noack?= <gnoack3000@gmail.com>, 
 linux-security-module@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794372885; l=1166;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=xaD9x5hOGi5bU7Yh+ce0HiRT3Akp4JNRN8QyWNIXG58=;
 b=o1+NYJLc/GsQlPVEcfpw+6EGdbF5/yRNquIi6RQb7zWg7iJHGvMT8vlyHXHquEooXjdnKCeOD
 /tr4JPiSF96BXKxKIdCQa2NZryQMhVALjr423/dTt/eSSyj6hf8K66a
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A task whose executable has an absolute path longer than 4106 bytes
triggers a WARN and cannot sandbox itself. Patch 2 adds selftests that
fail without patch 1.

Tested on v7.4-rc2 with KASAN and lockdep. landlock_restrict_self()
from 4107- and 4350-byte paths fails before the series and works after
it. The domain records then show exe="<too_long>". The other Landlock
selftests pass on both kernels, apart from five skipped hostfs tests.

---
Daejun Park (2):
      landlock: Fix landlock_restrict_self() failure on long executable paths
      selftests/landlock: Test a long executable path

 Documentation/admin-guide/LSM/landlock.rst         |   3 +-
 security/landlock/domain.c                         |  15 +-
 security/landlock/domain.h                         |   3 +-
 tools/testing/selftests/landlock/fs_test.c         | 175 +++++++++++++++++++++
 .../testing/selftests/landlock/wait-pipe-sandbox.c |   3 +-
 5 files changed, 192 insertions(+), 7 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261110-landlock-long-exe-61cbbfbc3300

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

