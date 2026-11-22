From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 11:27:16 -0300
Subject: [PATCH] docs/translations/pt_BR: process: add
 researcher-guidelines.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-researcher-guidelines-pt-br-v1-1-95204d57bd16@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSQrCQBAF0KuEWluQboeIV5EsevgmJdKGqkSEk
 Lvb6vJt3koGFRhdmpUULzF5lgq3ayiNoQxgydXkW39yzntWGIKmEcrDIhkPKTCeZo7K57g/Hro
 2RJ87qsOkuMn7t1/7v22Jd6T5W9K2fQA6TZvLfwAAAA==
X-Change-ID: 20261122-researcher-guidelines-pt-br-8b35470ab2d7
To: linux-doc@vger.kernel.org
Cc: skhan@linuxfoundation.org, rdunlap@infradead.org, 
 danielmaraboo@gmail.com, corbet@lwn.net, 
 Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795357635; l=11377;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=AEafsHSLVn+H2ZaqUNm5mIjCX8lWhQQVZKW0AnWYat0=;
 b=J3rEwQGJsz1NPOXM2lFmUP9oCxao5rSXQlf1D05MK3bwYVUmpoLsG7IYm6sezPN7SJDkXc1EI
 R2arjnfyNyfDPVezoKRcESGJGr+leokj2dMolIXJQi3mwV5dC5BdcVP
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Brazilian Portuguese translation of
Documentation/process/researcher-guidelines.rst, which describes what the
kernel community considers acceptable research practice, including the
guidance on surveys and on patches produced from research.

The translation follows the English original as last changed by commit
fdd100ee60a0 ("docs: process: use gender-neutral pronouns"). The example
commit log in the patches section is kept in English on purpose: it is a
model of a real commit message, not prose to be translated.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 Documentation/translations/pt_BR/process/index.rst |   1 +
 .../pt_BR/process/researcher-guidelines.rst        | 174 +++++++++++++++++++++
 2 files changed, 175 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/index.rst b/Documentation/translations/pt_BR/process/index.rst
index d072f7e46767..ff2400cd4b30 100644
--- a/Documentation/translations/pt_BR/process/index.rst
+++ b/Documentation/translations/pt_BR/process/index.rst
@@ -46,6 +46,7 @@ devem estar familiarizados.
    Adicionando uma nova chamada de Sistema <adding-syscalls>
    Por que a classe de tipo "volatile" não deve ser usada <volatile-considered-harmful>
    Como não Deixar as ioctls malfeitas <botching-up-ioctls>
+   Diretrizes para pesquisadores <researcher-guidelines>
 
 Guias de políticas e declarações de desenvolvedores
 ---------------------------------------------------
diff --git a/Documentation/translations/pt_BR/process/researcher-guidelines.rst b/Documentation/translations/pt_BR/process/researcher-guidelines.rst
new file mode 100644
index 000000000000..ba8219c4ec9d
--- /dev/null
+++ b/Documentation/translations/pt_BR/process/researcher-guidelines.rst
@@ -0,0 +1,174 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+.. _researcher_guidelines:
+
+Diretrizes para pesquisadores
++++++++++++++++++++++++++++++
+
+A comunidade do kernel Linux acolhe pesquisas transparentes sobre o kernel
+Linux, as atividades envolvidas em produzi-lo e quaisquer outros subprodutos
+do seu desenvolvimento. O Linux se beneficia muito desse tipo de pesquisa, e a
+maioria dos aspectos do Linux é movida por pesquisa, de uma forma ou de outra.
+
+A comunidade agradece muito quando os pesquisadores compartilham resultados
+preliminares antes de tornar os resultados públicos, especialmente se a
+pesquisa envolver segurança. O envolvimento antecipado melhora tanto a
+qualidade da pesquisa quanto a capacidade de o Linux evoluir a partir dela. Em
+qualquer caso, recomenda-se compartilhar com a comunidade cópias de acesso
+aberto da pesquisa publicada.
+
+Este documento procura esclarecer o que a comunidade do kernel Linux considera
+práticas aceitáveis e inaceitáveis ao conduzir esse tipo de pesquisa. No
+mínimo, tais pesquisas e atividades relacionadas devem seguir as regras padrão
+de ética em pesquisa. Para mais contexto sobre ética em pesquisa em geral,
+ética em tecnologia e pesquisa de comunidades de desenvolvedores em
+particular, veja:
+
+* `History of Research Ethics <https://www.unlv.edu/research/ORI-HSR/history-ethics>`_
+* `IEEE Ethics <https://www.ieee.org/about/ethics/index.html>`_
+* `Developer and Researcher Views on the Ethics of Experiments on Open-Source Projects <https://arxiv.org/pdf/2112.13217.pdf>`_
+
+A comunidade do kernel Linux espera que todos que interagem com o projeto
+participem de boa-fé para tornar o Linux melhor. Pesquisas sobre qualquer
+artefato disponível publicamente (incluindo, mas não se limitando a
+código-fonte) produzido pela comunidade do kernel Linux são bem-vindas,
+embora pesquisas sobre desenvolvedores devam ser explicitamente opt-in.
+
+Pesquisa passiva baseada inteiramente em fontes disponíveis publicamente,
+incluindo mensagens em listas de discussão públicas e commits em repositórios
+públicos, é claramente permitida. Ainda assim, como em qualquer pesquisa, a
+ética padrão deve ser seguida.
+
+Pesquisa ativa sobre o comportamento de desenvolvedores, porém, deve ser
+feita com o acordo explícito dos desenvolvedores individuais envolvidos e
+com divulgação completa a eles. Não se pode interagir com desenvolvedores,
+nem realizar experimentos com eles, sem consentimento; isso também é ética
+padrão em pesquisa.
+
+Questionários
+=============
+
+Pesquisas frequentemente assumem a forma de questionários enviados a
+mantenedores ou colaboradores. Como regra geral, porém, a comunidade do kernel
+tira pouco valor desses questionários. O processo de desenvolvimento do kernel
+funciona porque cada desenvolvedor se beneficia da sua participação, mesmo
+trabalhando com outros que têm objetivos diferentes. Responder a um
+questionário, no entanto, é uma demanda unilateral imposta a desenvolvedores
+ocupados, sem benefício correspondente para eles nem para a comunidade do
+kernel como um todo. Por essa razão, esse método de pesquisa é
+desaconselhado.
+
+Os membros da comunidade do kernel já recebem e-mail em excesso e
+provavelmente perceberão pedidos para responder a questionários como apenas mais uma
+demanda
+sobre o seu tempo. Enviar tais pedidos priva a comunidade de tempo valioso de
+colaboradores e dificilmente produzirá respostas estatisticamente úteis.
+
+Como alternativa, os pesquisadores devem considerar participar de eventos de
+desenvolvedores, promover sessões em que o projeto de pesquisa e os seus
+benefícios aos participantes possam ser explicados, e interagir diretamente
+com a comunidade nesses eventos. A informação obtida será muito mais rica do
+que a de um questionário por e-mail, e a comunidade também ganhará com a
+possibilidade de aprender com as suas percepções.
+
+Patches
+=======
+
+Para esclarecer: enviar patches a desenvolvedores *é* interagir com eles, mas
+eles já consentiram em receber *contribuições de boa-fé*. Enviar patches
+deliberadamente falhos ou vulneráveis, ou contribuir com informação enganosa
+nas discussões, não é algo consentido. Tal comunicação pode ser danosa ao
+desenvolvedor (por exemplo, consumindo tempo, esforço e disposição) e danosa
+ao projeto, ao erodir a confiança de toda a comunidade de desenvolvedores no
+colaborador (e na organização do colaborador como um todo), minando esforços
+para oferecer retorno construtivo aos colaboradores e colocando usuários
+finais em risco de falhas de software.
+
+A participação de pesquisadores no desenvolvimento do próprio Linux, como a de
+qualquer pessoa, é bem-vinda e incentivada. Pesquisar o código do Linux é
+prática comum, especialmente no que diz respeito a desenvolver ou executar
+ferramentas de análise que produzam resultados que permitam ação concreta.
+
+Ao interagir com a comunidade de desenvolvedores, enviar um patch tem sido
+tradicionalmente a melhor forma de causar impacto. O Linux já tem muitos bugs
+conhecidos; muito mais útil é ter correções verificadas. Antes de contribuir,
+leia com atenção a documentação apropriada:
+
+* Documentation/process/development-process.rst
+* Documentation/process/submitting-patches.rst
+* Documentation/admin-guide/reporting-issues.rst
+* Documentation/process/security-bugs.rst
+
+Em seguida, envie um patch (incluindo um log de commit com todos os detalhes
+listados abaixo) e acompanhe qualquer retorno de outros desenvolvedores.
+
+Ao enviar patches produzidos a partir de pesquisa, os logs de commit devem
+conter ao menos os detalhes a seguir, para que os desenvolvedores tenham
+contexto adequado para entender a contribuição. Responda:
+
+* Qual é o problema específico encontrado?
+* Como o problema poderia ser alcançado em um sistema em execução?
+* Que efeito o problema teria sobre o sistema quando ocorresse?
+* Como o problema foi encontrado? Inclua especificamente detalhes sobre
+  qualquer teste, programas de análise estática ou dinâmica, e quaisquer
+  outras ferramentas ou métodos usados para realizar o trabalho.
+* Em qual versão do Linux o problema foi encontrado? É fortemente preferível
+  usar a versão mais recente ou um branch recente do linux-next (veja
+  Documentation/process/howto.rst).
+* O que foi alterado para corrigir o problema, e por que se acredita que está
+  correto?
+* Como a mudança foi testada em compilação e em tempo de execução?
+* Qual commit anterior esta mudança corrige? Isso deve ir em uma tag "Fixes:"
+  como a documentação descreve.
+* Quem mais revisou este patch? Isso deve ir em tags "Reviewed-by:"
+  apropriadas; veja abaixo.
+
+Por exemplo::
+
+  From: Author <author@email>
+  Subject: [PATCH] drivers/foo_bar: Add missing kfree()
+
+  The error path in foo_bar driver does not correctly free the allocated
+  struct foo_bar_info. This can happen if the attached foo_bar device
+  rejects the initialization packets sent during foo_bar_probe(). This
+  would result in a 64 byte slab memory leak once per device attach,
+  wasting memory resources over time.
+
+  This flaw was found using an experimental static analysis tool we are
+  developing, LeakMagic[1], which reported the following warning when
+  analyzing the v5.15 kernel release:
+
+   path/to/foo_bar.c:187: missing kfree() call?
+
+  Add the missing kfree() to the error path. No other references to
+  this memory exist outside the probe function, so this is the only
+  place it can be freed.
+
+  x86_64 and arm64 defconfig builds with CONFIG_FOO_BAR=y using GCC
+  11.2 show no new warnings, and LeakMagic no longer warns about this
+  code path. As we don't have a FooBar device to test with, no runtime
+  testing was able to be performed.
+
+  [1] https://url/to/leakmagic/details
+
+  Reported-by: Researcher <researcher@email>
+  Fixes: aaaabbbbccccdddd ("Introduce support for FooBar")
+  Signed-off-by: Author <author@email>
+  Reviewed-by: Reviewer <reviewer@email>
+
+Se você é colaborador de primeira viagem, recomenda-se que o próprio patch
+seja verificado por outras pessoas em particular antes de ser publicado nas
+listas públicas. (Isso é obrigatório se lhe disseram explicitamente que os
+seus patches precisam de revisão interna mais cuidadosa.) Espera-se que essas
+pessoas tenham a sua tag "Reviewed-by" incluída no patch resultante. Encontrar
+outro desenvolvedor familiarizado com a contribuição ao Linux, especialmente
+dentro da sua própria organização, e pedir que ele ajude com revisões antes de
+enviar os patches às listas públicas costuma melhorar significativamente a
+qualidade dos patches resultantes e, com isso, reduz a carga sobre os outros
+desenvolvedores.
+
+Se ninguém puder ser encontrado para revisar patches internamente e você
+precisar de ajuda para encontrar essa pessoa, ou se tiver qualquer outra
+dúvida relacionada a este documento e às expectativas da comunidade de
+desenvolvedores, entre em contato com a lista privada do Technical Advisory
+Board: <tech-board@groups.linuxfoundation.org>.

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-researcher-guidelines-pt-br-8b35470ab2d7

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>

