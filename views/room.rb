<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="utf-8" />
    <title>HTML5 Drawing</title>
    <link rel="stylesheet" href="http://yui.yahooapis.com/2.8.0r4/build/reset/reset-min.css"> 
    <link rel="stylesheet" href="/style.css" type="text/css" />
    <script type="text/javascript" src="/cpick.js"></script>
    <script type="text/javascript" src="/jquery-1.4.2.min.js"></script>
    <script type="text/javascript" src="/modernizr-1.5.min.js"></script>
    <script type="text/javascript">
      var drawing = false;
      var canvas;
      var ctx;
      var mouseX;
      var mouseY;
      var fillWidth; 
      var tempLineData;
      var ws_paint;
      var ws_chat;

      $(document).ready(function() {
        /** お絵かきの処理 **/
        var message = function(str){ $("#msg").prepend(str); };
        fillWidth = parseInt($('#widthSelect').val());

        var post_comment = function() {
          if($('#comment').val() != ""){
            ws_chat.send($('#comment').val());
            $('#comment').val('');
          }
        }

        ws_chat = new WebSocket("ws://<%= request.host %>:8080/chat?room=<%= @room %>&user=<%= @user %>");
        ws_chat.onmessage = function(evt) { 
          var data = JSON.parse(evt.data);
          $("#comments").prepend([
            "<tr>", 
            "<td class='time'>[", data['time'], "]</td>", 
            "<td class='user_name'>", data['user'], "</td>",
            "<td class='comment'>",   data['comment'], "</td>", 
            "</tr>"
            ].join('')); 
        };
        ws_chat.onclose = function() { message("接続が解除されました。"); };
        ws_chat.onopen = function()  { message("入室しました。"); }
        
        $("#comment_form").submit(function(e){
          post_comment();
          return false;
        });

        /** お絵かきの処理 **/

        // 各種データの初期化
        canvas = document.getElementById('mainCanvas');
        ws_paint = new WebSocket("ws://<%= request.host %>:8080/paint?room=<%= @room %>&user=<%= @user %>");

        // データの受信処理
        ws_paint.onmessage = function(evt) {
          var data = JSON.parse(evt.data);
          if(data['clear']) {
            clearCanvas();
          } else {
            drawLine(data.start, data.middle, data.dest, data.color, data.width);
          }
        }

        // 線幅
        $('#widthSelect').change(function() {
          fillWidth = parseInt($('#widthSelect').val());
        });

        // 以下、キャンバス関連
        if(canvas) {
          ctx = canvas.getContext("2d");
          ctx.lineCap = 'round';
          ctx.lineJoin = 'round';

          $('#mainCanvas').bind("mousedown", function() {
            tempLineData = {};
            tempLineData.coodinates = new Array();
            tempLineData.color = $('#colorBox').val() ? $('#colorBox').val() : '#000000';
            tempLineData.width = fillWidth;
            drawing = true;
          });
          $('#mainCanvas').bind("mouseup", function()  { drawing = false; });
          $('#mainCanvas').bind("mouseout", function() { drawing = false; });
          $('#mainCanvas').mousemove(function(e) {
            if(drawing) {
              adjustXY(e);
              tempLineData.coodinates.push({x: mouseX, y:mouseY});

              if(tempLineData.coodinates.length >= 3) {
                var start = tempLineData.coodinates.shift();
                var middle = tempLineData.coodinates[0];
                var dest = tempLineData.coodinates[1];

                //drawLine(start, middle, dest, tempLineData.color, tempLineData.width);
                // データの送信
                ws_paint.send(JSON.stringify({'start': start, 'middle': middle, 'dest': dest, 'color': tempLineData.color, 'width': tempLineData.width}));
              }
            }
          });

          $('#clearButton').removeAttr('disabled');
          $('#clearButton').click(function() {
            if(window.confirm('キャンバス消します')) {
              ws_paint.send(JSON.stringify({'clear': true}));
              //clearCanvas();
            }
          });

          var clearCanvas = function() {

            ctx.clearRect(0, 0, canvas.width, canvas.height);
            alert('キャンバスがクリアされました。');
          }

          if(Modernizr.localstorage) {
            var attachLoadImageEvent = function(){
              $('#loadButton').removeAttr('disabled');
              $('#loadButton').click(function() {
                if(window.confirm('保存した画像をロードします。現在のデータは消えます。')) {
                  var image = new Image();
                  image.onload = function() {
                    ctx.clearRect(0, 0, canvas.width, canvas.height);
                    ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
                  }
                  image.src = window.localStorage.imageData;
                }
              });
            }

            $('#saveButton').removeAttr('disabled');
            $('#saveButton').click(function() {
              if(window.confirm('すでにデータがあるなら上書きされます')) {
                window.localStorage.imageData = canvas.toDataURL("image/png");
                attachLoadImageEvent();
              }
            });

            if(window.localStorage.imageData) {
              attachLoadImageEvent();
            }

          }
        }
      });

      // 座標の補正
      function adjustXY(e) {
        var rect = e.target.getBoundingClientRect();
        mouseX = e.clientX - rect.left;
        mouseY = e.clientY - rect.top;
      }

      // 実線の描画
      function drawLine(start, middle, dest, color, width) {
        var x1 = (start.x + middle.x) / 2;
        var x2 = (dest.x + middle.x) / 2;
        var y1 = (start.y + middle.y) / 2;
        var y2 = (dest.y + middle.y) / 2;

        ctx.strokeStyle = color;
        ctx.lineWidth = width;
        ctx.beginPath();
        ctx.moveTo(x1, y1);
        ctx.quadraticCurveTo(middle.x, middle.y, x2, y2);
        ctx.stroke();
      }
    </script>
  </head>
  <body>
    <header id="mainHeader">
      <h1>おえかきちゅっちゅ♥</h1>
      <nav>
        <ul>
          <li>メニュー</li>
          <li>を</li>
          <li>いれる</li>
        </ul>
      </nav>
    </header>

    <section id="mainSection">
      <canvas id="mainCanvas" width="640" height="480"></canvas>
      <section>
        <label>線幅 :</label>
        <select name="widthSelect" id="widthSelect">
          <option value="1">1px</option>
          <option value="3" selected="selected">3px</option>
          <option value="5">5px</option>
          <option value="7">7px</option>
          <option value="530000">53万px</option>
        </select>
      </section>
      <section>
        <label>色選択 :</label>
        <input type="text" class="html5jp-cpick [coloring:true]" name="colorBox" id="colorBox" value="" size="12" />
      </section>
      <section>
        <button type="button" name="saveButton" id="saveButton" disabled="disabled">保存</button>
        <button type="button" name="loadButton" id="loadButton" disabled="disabled">ロード</button>
        <button type="button" name="clearButton" id="clearButton" disabled="disabled">クリア</button>
      </section>
    </section>
    <section id="chatSection">
      <h2>チャット</h2>
      <div id="form">
        <form id=comment_form>
          <input type=text id=comment size=30 />
          <input type=submit id=submit value=発言する />
        </form>
        <p id=msg></p>
      </div>
      <table id="comments">
      </table>
    </section>

    <footer id="mainFooter">
      <address>Created by <a href="http://twitter.com/projecthl2" target="_blank">@projecthl2</a> &amp; <a href="http://twitter.com/ecpplus" target="_blank">@ecpplus</a></address>
    </footer>
  </body>
</html>