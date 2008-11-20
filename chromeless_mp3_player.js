
function swf(movieName) {
  if (navigator.appName.indexOf("Microsoft") != -1) {
//    alert('win');
    return window[movieName];
  }
  else {
    return document[movieName];
  }
}

function ChromelessMP3Player(elm_id) {
  this.player;
  this.id = elm_id;
  this._embed();
}
ChromelessMP3Player.prototype = {
  _embed: function() {
    var width = 1;
    var height = 1;
    var flashvars = {};
    var params = {id: this.id};
    var attributes = params;
    swfobject.embedSWF("MP3Player.swf?ver=2",
                       this.id,
                       width.toString(),
                       height.toString(),
                       "9.0.0",
                       "expressInstall.swf", 
                       flashvars,
                       params,
                       attributes);
  }
  ,
  load: function(url) {
    this.player.extLoad(url);
  }
  ,
  play: function() {
    this.player.extPlay();
    alert('play')
  }
  ,
  pause: function() {
  }
  ,
  stop: function() {
    this.player.extStop();
    alert('stop')
  }
  ,
  getLoadingInfo: function() {
    return this.player.extGetLoadingInfo();
  }
  ,
  onStateChange: function() {
  }
};
//var mp3player = new ChromelessMP3Player();
//function onChromelessMP3PlayerReady() {
//  mp3player.player = document.getElementById('mp3player');
//  mp3player.player.addEventListener('onStateChange', 'mp3player.onStateChange');
//}
