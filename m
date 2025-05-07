From: Chen Linxuan <chenlinxuan@uniontech.com>
Subject: [PATCH 0/2] Add a documentation for FUSE passthrough
Date: Wed, 07 May 2025 13:16:40 +0800
Message-Id: <20250507-fuse-passthrough-doc-v1-0-cc06af79c722@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALjsGmgC/x3MPQqAMAxA4atIZgO1Wv+uIg6lRpvFSmNFEO9uc
 fyG9x4QikwCY/FApIuFw55RlQU4b/eNkJds0EobZVSHaxLCw4qcPoa0eVyCQzNQ5fqm1ratIad
 HpJXvfzvN7/sBdraXHmYAAAA=
X-Change-ID: 20250507-fuse-passthrough-doc-59e1c8432a63
To: Miklos Szeredi <miklos@szeredi.hu>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>, 
 Amir Goldstein <amir73il@gmail.com>, 
 Bernd Schubert <bernd.schubert@fastmail.fm>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=856;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=cCqunWSORWZI8+ZRM7yH3lgkp1MPBBW/HJ0FseqYOb8=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoGuzGnXpdf4wjT49f5TuSBlWPOSu46SsfICKlq
 coRoJzg4HmJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaBrsxgAKCRB2HuYUOZmu
 i/yWEADblVtLmhPYCzinPo/tpVOfHQdsnQyolkhroTZGXwKLDUtsCD9uiXMjvhDgmMaOXknb1j+
 /L3hstwT8BKOa3O2LHEUWgXWJiZxUahQYD4q2mTbtnE5DwSR/ykrRGzueUAZ161cOyZM0wbgw61
 8akuzKEmi6rVkNshJ4mx/nYi4yW3YXBLzCioMRX/aCdyMM4BrKg8OTWFSYCHOGxB9LAJs+/XiZP
 j49wZbn+JXjB9/iPB6owXXB8CyniuN+js24AxdtekDzUWxPokzFbatZ53Y4LpojvIzAkPtTUxgP
 EtIYg8uQ8w3QetHf6nMv8lhf1Re1zd9FWpxH4SKCL/GlVApmqXwlS/LZcHaZK5wkGCfYJt3m/9z
 3xO0o6K40CkVPd69Xj+Xoff0/lc5vwQ4H2+vm2j+yS++eCTVC0OVntT7g6bkzs0XRfxmM90suU3
 Peh5EESw1WnURXuvrQwLzjj2Y7FjYPnWqNF9sxXFWQd22xaQ3jD9pGfaBMWwcxUul3kPCPchFmz
 b5z0DVi1aEVPtBizxOmpwdYAbiS/IQNPMLnNHCpZ1q4jqDZWMGdj2s1We43AzFp45mygnDbjJjo
 nuabXUjOuDST2SEp3y7e+lFkdIYYMu6oK9xtq8id8AB6YPgCl35/iJmIDIHLg5y9QlUYBNKDop1
 MgU/7DszgZrhGXg==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a new file,
Documentation/filesystems/fuse-passthrough.rst, which documents why
FUSE passthrough functionality requires CAP_SYS_ADMIN capabilities.

The series also updates the MAINTAINERS file to ensure
scripts/get_maintainer.pl works correctly with FUSE documentation.

Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
Chen Linxuan (2):
      MAINTAINERS: update filter of FUSE documentation
      docs: filesystems: add fuse-passthrough.rst

 Documentation/filesystems/fuse-passthrough.rst | 139 +++++++++++++++++++++++++
 MAINTAINERS                                    |   2 +-
 2 files changed, 140 insertions(+), 1 deletion(-)
---
base-commit: 0d8d44db295ccad20052d6301ef49ff01fb8ae2d
change-id: 20250507-fuse-passthrough-doc-59e1c8432a63

Best regards,
-- 
Chen Linxuan <chenlinxuan@uniontech.com>

