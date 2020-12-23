/// <reference types="cypress" />

/// JSON fixture file can be loaded directly using
// the built-in JavaScript bundler
// @ts-ignore
// const requiredExample = require('../fixtures/example')

context('Files', () => {
  beforeEach(() => {
    cy.visit('http://3.249.245.10/')
  })

  it('login', () => {
    //cy.get('input[name=email]').type('user')
	//cy.get('input[name=password]').type('password')
	//cy.get('button[type=submit]').click()
	const uploadfile = 'a.pdf';
	cy.get('input[type=file]').attachFile(uploadfile)
	cy.get('button[data-test-id=buttonFileDropDownloadXml]:not(hidden)').should('be.hidden')
	cy.get('button[data-test-id=buttonFileDropDownloadPdf]:not(hidden)').should('be.hidden')
  })

})
