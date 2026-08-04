From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 04 Aug 2026 18:55:05 +0800
Subject: [PATCH 5/5] NFSv4/flexfiles: bound stripe_unit to 32 bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-nfs-fixes-v1-5-1544df970e7c@outlook.com>
References: <20260804-nfs-fixes-v1-0-1544df970e7c@outlook.com>
In-Reply-To: <20260804-nfs-fixes-v1-0-1544df970e7c@outlook.com>
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Curley <jcurley@purestorage.com>, 
 Michael Bommarito <michael.bommarito@gmail.com>, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1936;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=gwCePfOLU7Ur1xZ+XPeOVksWgOrn9f4Gb+eoyLnBV3c=;
 b=kA0DAAoWceg4UIuO8EAByyZiAGpxxRzIk0abGAjx0LSUqTnsDzjv8iOA4XR6S1QCHe7MarJf2
 Ih1BAAWCgAdFiEEx3DS9jhNtC20TLRjceg4UIuO8EAFAmpxxRwACgkQceg4UIuO8EDN2AD9ES3i
 sjhlNcAyA9pPJbc6SPzfh5lFny7McKbAjBbP3S4A/3o7xhRHRHkUIcXalxGoviYkPXHHom/utYl
 13jQ1NbgI
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ff_layout_alloc_lseg() decodes stripe_unit from the flexfiles LAYOUTGET
body as a 64-bit value and validates it as one:

	if (dss_count > 1 && stripe_unit == 0)
		goto out_err_free;

but every consumer divides by only its low 32 bits.  ff_layout_pg_test()
narrows it explicitly:

	u32 stripe_unit = FF_LAYOUT_LSEG(pgio->pg_lseg)->stripe_unit;
	...
	do_div(p_stripe, stripe_unit);

and nfs4_ff_layout_calc_dss_id() passes the u64 straight to do_div(),
which narrows the divisor itself.

A server-supplied non-zero multiple of 2^32 such as 0x100000000
therefore passes the check and reaches both dividers as a zero divisor,
so the first read or write through the layout takes a divide error and
panics the client.  The same narrowing silently turns any other value
above U32_MAX into an unrelated stripe size.

Values that do not fit in 32 bits are not representable by the
arithmetic this driver performs on stripe_unit, so reject them at decode
time rather than truncating them.

Fixes: 20b1d75fb840 ("NFSv4/flexfiles: Add support for striped layouts")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 fs/nfs/flexfilelayout/flexfilelayout.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/fs/nfs/flexfilelayout/flexfilelayout.c b/fs/nfs/flexfilelayout/flexfilelayout.c
index bdc4b960eeb7..63391f48c5d9 100644
--- a/fs/nfs/flexfilelayout/flexfilelayout.c
+++ b/fs/nfs/flexfilelayout/flexfilelayout.c
@@ -515,7 +515,8 @@ ff_layout_alloc_lseg(struct pnfs_layout_hdr *lh,
 		    dss_count == 0)
 			goto out_err_free;
 
-		if (dss_count > 1 && stripe_unit == 0)
+		if (dss_count > 1 &&
+		    (stripe_unit == 0 || stripe_unit > U32_MAX))
 			goto out_err_free;
 
 		fls->mirror_array[i] = ff_layout_alloc_mirror(dss_count, gfp_flags);

-- 
2.51.2

