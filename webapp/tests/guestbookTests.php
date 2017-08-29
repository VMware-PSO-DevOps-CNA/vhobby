<?php
class GitHubTest extends PHPUnit_Framework_TestCase {

    /**
     * @var \RemoteWebDriver
     */
    protected $webDriver;

    public function setUp() {
        $capabilities = array(WebDriverCapabilityType::BROWSER_NAME => 'firefox');
        $this->webDriver = RemoteWebDriver::create('http://localhost:4444/wd/hub', $capabilities);
    }

    protected $url = 'http://vhobby';

    public function testFindCustomerFeedback() {
        $this->webDriver->get($this->url);
        //$this->assertContains('Virtual', $this->webDriver->getTitle());
        //$element = $this->webDriver->findElement(WebDriverBy::xpath("//h4[contains(text(), 'By demouser')]"));
        $this->assertContains('By demouser', $this->webDriver->getPageSource());
 }
}
?>
