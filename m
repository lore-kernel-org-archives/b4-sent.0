From: Joel Granados <j.granados@samsung.com>
Date: Mon, 02 Oct 2023 10:55:24 +0200
Subject: [PATCH v2 07/15] macintosh: Remove the now superfluous sentinel
 element from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-7-02dd0d46f71e@samsung.com>
References: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-0-02dd0d46f71e@samsung.com>
In-Reply-To: <20231002-jag-sysctl_remove_empty_elem_drivers-v2-0-02dd0d46f71e@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, willy@infradead.org, 
 josh@joshtriplett.org, Kees Cook <keescook@chromium.org>, 
 Phillip Potter <phil@philpotter.co.uk>, 
 Clemens Ladisch <clemens@ladisch.de>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Juergen Gross <jgross@suse.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Oleksandr Tyshchenko <oleksandr_tyshchenko@epam.com>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 "James E.J. Bottomley" <jejb@linux.ibm.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Doug Gilbert <dgilbert@interlog.com>, 
 Sudip Mukherjee <sudipm.mukherjee@gmail.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>, 
 Corey Minyard <minyard@acm.org>, Theodore Ts'o <tytso@mit.edu>, 
 "Jason A. Donenfeld" <Jason@zx2c4.com>, David Ahern <dsahern@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Robin Holt <robinmholt@gmail.com>, Steve Wahl <steve.wahl@hpe.com>, 
 Russ Weight <russell.h.weight@intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Song Liu <song@kernel.org>, 
 "K. Y. Srinivasan" <kys@microsoft.com>, 
 Haiyang Zhang <haiyangz@microsoft.com>, Wei Liu <wei.liu@kernel.org>, 
 Dexuan Cui <decui@microsoft.com>, Jani Nikula <jani.nikula@linux.intel.com>, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Tvrtko Ursulin <tvrtko.ursulin@linux.intel.com>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>
Cc: Joel Granados <j.granados@samsung.com>, linux-kernel@vger.kernel.org, 
 xen-devel@lists.xenproject.org, linux-serial@vger.kernel.org, 
 linux-scsi@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-rdma@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 netdev@vger.kernel.org, linux-raid@vger.kernel.org, 
 linux-hyperv@vger.kernel.org, intel-gfx@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=912; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=c34FrDvRsuK3W5VxNHhzTVZ4EpvxmdCHO9VF2TbEJQM=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlGoV9BM0qHj8XlYlHwvsY27mE0p7Q50fHd/x3m
 mamAQ6k40OJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZRqFfQAKCRC6l81St5ZB
 T+ktC/9hHJ3tzmqocKUjOWy67m0gsFX+WmzFOM1VWX4Xx68Thf2Xh9rp1PbKUomC5Wypz4sEz+/
 DH8udTCz1xwKfRQ4neRh4N91gxFjMM/bXB/33iT8dKbD2BSynm/sWAbYjtTG0u+j1G35lBAfKFl
 rTp6Tu6TxNe+RIcwAfU79Wi/FOzIBwNvsUwdviYDrLxFse3xM5Kf3rghGM/5bunNk3qmWvbxV35
 eb1ODj2kUBMjd6w5vWbsrdvRGSXiy/D8wwKkOC6+HzDkRgPxHusILte3pIBAMUilO+rWF3dktI3
 YacFGr8OQvVODccQ2G/hCi3YSkxkDjes1yBh8L/+/D9Zv/lWhU1SnXI+91LCZljVERXOj/qbZKt
 8FlI1sBruSoMxd31onJ4x9loaKtD+75XozhNKZouQsbbJj96fQPnvr3+gwgziNkXiMPElz7Bv7T
 81pALQhara797OJM8h5V1xw7n9CkuNCysxLg967rj79aFG6UaQfdNIA9PKkBSzlcXc+/k=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from mac_hid_files

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/macintosh/mac_hid.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/macintosh/mac_hid.c b/drivers/macintosh/mac_hid.c
index d8c4d5664145..1ae3539beff5 100644
--- a/drivers/macintosh/mac_hid.c
+++ b/drivers/macintosh/mac_hid.c
@@ -236,7 +236,6 @@ static struct ctl_table mac_hid_files[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec,
 	},
-	{ }
 };
 
 static struct ctl_table_header *mac_hid_sysctl_header;

-- 
2.30.2

