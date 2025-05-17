<?xml version="1.0" encoding="UTF-8"?>
<transform
    version="1.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:br="http://jabarsz.cz/Breezipe"
    xmlns:exsl="http://exslt.org/common">

  <import href="./common.xsl" />
  <import href="./classic-style.xsl" />
  <import href="./joy-of-cooking-style.xsl" />
  <import href="./step-table.xsl" />
  <output indent="yes" />
  <param name="css" select="'/recipe.css'" />
  <param name="js" select="'/highlight-crossrefd.js'" />

  <template match="/br:recipe|/br:recipes">
    <xhtml:html>
      <if test="@xml:lang">
        <attribute name="xml:lang">
          <value-of select="@xml:lang" />
        </attribute>
        <attribute name="lang">
          <value-of select="@xml:lang" />
        </attribute>
      </if>
      <variable name="title-tmp">
        <call-template name="get-name" />
      </variable>
      <variable name="title" select="exsl:node-set($title-tmp)" />
      <xhtml:head>
        <xhtml:link rel="stylesheet" type="text/css">
          <attribute name="href">
            <value-of select="$css" />
          </attribute>
        </xhtml:link>
        <if test="$title != ''">
          <xhtml:title><copy-of select="$title" /></xhtml:title>
        </if>
      </xhtml:head>
      <xhtml:body>
        <if test="$title != ''">
          <xhtml:h1><copy-of select="$title" /></xhtml:h1>
        </if>
        <xhtml:div class="container">
          <apply-templates select="." mode="body" />
        </xhtml:div>
        <xhtml:script>
          <attribute name="src">
            <value-of select="$js" />
          </attribute>
        </xhtml:script>
      </xhtml:body>
    </xhtml:html>
  </template>

  <template match="xhtml:*" mode="body">
    <copy-of select="." />
  </template>

  <template match="br:recipe" mode="body">
    <xhtml:div class="recipe">
      <if test="parent::*">
        <xhtml:h2><call-template name="get-name" /></xhtml:h2>
      </if>
      <copy-of select="br:step/preceding-sibling::xhtml:*" />
      <xhtml:div class="recipe-container">
        <xhtml:div class="section step-table">
          <call-template name="step-table" />
        </xhtml:div>
        <xhtml:div class="section instructions">
          <for-each select=".">
            <call-template name="classic-steps" />
          </for-each>
        </xhtml:div>
      </xhtml:div>
      <copy-of select="br:step/following-sibling::xhtml:*" />
    </xhtml:div>
  </template>

</transform>
