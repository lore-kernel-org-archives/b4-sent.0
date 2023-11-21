From: Joel Granados <j.granados@samsung.com>
Subject: [PATCH 0/3] sysctl: Fix out of bounds access for empty syscl
 ctl_tables
Date: Tue, 21 Nov 2023 12:02:17 +0100
Message-Id: <20231121-jag-fix_out_of_bounds_insert-v1-0-571e76d51316@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADmOXGUC/x3M0QpAMBSA4VfRubZyJsKrSAs7OC42bSYl7+7k8
 q+/74FIgSlClz0Q6OLI3klgnsG8jW4lxVYadKFLRI1qH1e18G18Oo1fzOSTs9GwE+dUTV02hcV
 pbisCIY5A8v58P7zvB5ua+PduAAAA
To: Luis Chamberlain <mcgrof@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Iurii Zaikin <yzaikin@google.com>, Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <j.granados@samsung.com>, 
 kernel test robot <oliver.sang@intel.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=1393;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=waK/FluF/0krz7P2EuXZZxwQvvul2q1uEU1amrgpPY4=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlXI5Bb9fXe1+ayTIwE5DrkG+25/f5YkzJkmQ/Y
 MuepmzywQKJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZVyOQQAKCRC6l81St5ZB
 TxCNC/sFb9mBVPyryzZcNJpAc4PU4j02U0mOdP9qGZdLWXQvI0kb1OCJn0klYpgDXe0xcJGNrpB
 buDWLP/BzQDx8tdJXqW1wrECYKix09cL23jZ5wt4Wo+AIyo+wzGtddrIuid3o0xOF+JmSmLaJKb
 dmHZBUhehC6I8irVKm2qH4/RBz7jpefsrdHRfuXS6v99Bv1BvK5mrhYMbvrO2POHUnY2dxMdshL
 kr6YTLclBFuxdR6LqhKJAYi5xyCOeUxEJRxqHtPk39/a423D2gDuRmdH3JCVgSc+2cVRrfK+wfg
 erXBDDIEPvFANKGGGsynXZuW4Q41VjhAWuqTjX+pGY0V7tjkB47Enbvq23eN7NjbKvGNsU0ayOL
 t8FdsqZ7pvGqWNY7l9VTsCXK/XouoAYUaZ18eG89khbkm8zihfDOb0qxYdH/yCeNCkCwMWlQZkw
 j+QI7o1cY2NPFDqEzGRKLFMRtTsnSk2zZ+KXcPW5PJx1xK5ru6iLjxxfKT5SC3bJ/6wtA=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix an out of bounds access reported in
https://lore.kernel.org/oe-lkp/202311201431.57aae8f3-oliver.sang@intel.com
Make sure that the ctl_table header size is greater than 0 before
evaluating if a ctl_table is permanently empty; this evaluation accesses
the first element regardless of the size. Adjusted the ctl_table_size of
Permanently empty ctl_table registers to 1 as they the check now
requires them to have size greater than 0. Added tests for empty
directory handling; in response to the path followed by empty ctl_tables
changing slightly. Clarified the results of sysctl self tests to more
easily identify which ones are OK, Skipped and Failed.

Comments are greatly appreciated

Best

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
Joel Granados (3):
      sysctl: Fix out of bounds access for empty sysctl registers
      sysctl: Add a selftest for handling empty dirs
      sysclt: Clarify the results of selftest run

 fs/proc/proc_sysctl.c                    |   9 +-
 lib/test_sysctl.c                        |  29 ++++++
 tools/testing/selftests/sysctl/sysctl.sh | 146 ++++++++++++++++++-------------
 3 files changed, 121 insertions(+), 63 deletions(-)
---
base-commit: 8b793bcda61f6c3ed4f5b2ded7530ef6749580cb
change-id: 20231121-jag-fix_out_of_bounds_insert-86380d1bc95e

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

