
var _setTimeout = window.setTimeout;

var setTimeout = function(f) {
    requestAnimationFrame(function() {
        document.forms[0]._submit = document.forms[0].submit;
        document.forms[0].submit = function() {
            console.log(this['jschl_vc'].value);
            console.log(this['pass'].value);
            console.log(this['jschl-answer'].value);
            window.opener.postMessage({from: 'torrentz', kind: 'done'}, '*');
            //HTMLFormElement.prototype.submit.call(this);
            document.forms[0]._submit();
        };
        _setTimeout(f, 4000);
    });
};
