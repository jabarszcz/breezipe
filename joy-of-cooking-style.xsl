<?xml version="1.0" encoding="UTF-8"?>
<transform
    version="1.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:br="http://jabarsz.cz/Breezipe"
    xmlns:exsl="http://exslt.org/common">

  <import href="./common.xsl" />
  <output indent="yes" />

  <!-- Entry point template -->
  <template name="joy-steps">
    <param name="with-targets" select="true()" />
    <xhtml:ol>
      <apply-templates select="br:step" mode="joy">
        <with-param name="with-targets" select="$with-targets" />
      </apply-templates>
    </xhtml:ol>
  </template>

  <template match="br:step" mode="joy">
    <param name="with-targets" select="true()" />
    <xhtml:li>
      <call-template name="class-attr">
        <with-param name="extra-classes" select="'step'" />
      </call-template>
      <if test="$with-targets">
        <call-template name="target" />
      </if>
      <if test="@short">
        <xhtml:b><value-of select="@short" />. </xhtml:b>
      </if>
      <apply-templates mode="joy">
        <with-param name="with-targets" select="$with-targets" />
      </apply-templates>
    </xhtml:li>
  </template>

  <!-- Don't copy "structural" elements in this mode, individual
       templates will choose to where/how to display them.  -->
  <template match="br:name|br:note" mode="joy" />

  <!-- Copy the xhtml to the output -->
  <template match="xhtml:*" mode="joy">
    <copy-of select="." />
  </template>

  <template match="br:group" mode="joy">
    <param name="with-targets" select="true()" />
    <xhtml:table>
      <xhtml:tbody>
        <variable name="group-name-tmp">
          <call-template name="get-name" />
        </variable>
        <variable name="group-name" select="exsl:node-set($group-name-tmp)" />
        <if test="$group-name != ''">
          <xhtml:tr>
            <call-template name="class-attr" />
            <if test="$with-targets">
              <call-template name="target" />
            </if>
            <xhtml:th colspan="2">
              <call-template name="link">
                <with-param name="text" select="$group-name" />
              </call-template>
            </xhtml:th>
          </xhtml:tr>
        </if>
        <apply-templates select="br:ingredient" mode="joy-table">
          <with-param name="with-targets" select="$with-targets" />
        </apply-templates>
      </xhtml:tbody>
    </xhtml:table>
  </template>

  <template match="br:ingredient" mode="joy-table">
    <param name="with-targets" select="true()" />
    <xhtml:tr>
      <if test="$with-targets">
        <call-template name="target" />
      </if>
      <call-template name="class-attr" />
      <xhtml:td>
        <call-template name="get-quantity" />
      </xhtml:td>
      <xhtml:td>
        <call-template name="link">
          <with-param name="extra-classes">ingredient</with-param>
        </call-template>
        <if test="@note"> (<value-of select="@note" />)</if>
        <if test="br:note"> (<copy-of select="br:note/node()" />)</if>
      </xhtml:td>
    </xhtml:tr>
  </template>

  <template match="br:ingredient" mode="joy">
    <param name="with-targets" select="true()" />
    <xhtml:table>
      <xhtml:tbody>
        <apply-templates select="." mode="joy-table">
          <with-param name="with-targets" select="$with-targets" />
        </apply-templates>
      </xhtml:tbody>
    </xhtml:table>
  </template>

  <template match="br:ref" mode="joy">
    <xhtml:span>
      <attribute name="class">
        <text>crossrefd </text>
        <value-of select="@r" />
      </attribute>
      <attribute name="data-crossref"><value-of select="@r" /></attribute>
      <xhtml:a class="internal">
        <attribute name="href">#<value-of select="@r" /></attribute>
        <choose>
          <when test="node()">
            <apply-templates /> <!-- Copy inner text/xhtml -->
          </when>
          <otherwise>
            <apply-templates select="key('id', @r)" mode="get-name-or-id" />
          </otherwise>
        </choose>
      </xhtml:a>
      <call-template name="qty-note-parens" />
    </xhtml:span>
  </template>

  <template match="br:result" mode="joy">
    <param name="with-targets" select="true()" />
    <call-template name="link">
      <with-param name="extra-classes">
        <call-template name="crossrefd" />
      </with-param>
      <with-param name="extra-attrs-from">
        <xhtml:a>               <!-- Dummy node to pass attrs -->
          <if test="$with-targets">
            <call-template name="target" />
          </if>
          <attribute name="data-crossref">
            <call-template name="get-id" />
          </attribute>
        </xhtml:a>
      </with-param>
    </call-template>
  </template>

</transform>
