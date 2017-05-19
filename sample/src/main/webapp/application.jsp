<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*,java.net.*,java.io.*,org.json.simple.*,org.json.simple.parser.*" %>
<html>
    <head></head>
    <body>
        <%
           String userEmail = request.getParameter("user");
           PrintWriter writer = response.getWriter();
           if(userEmail != null && userEmail.endsWith("@sungardas.com"))
           {
             //
             //
             // Make a POST request 
             //   - To https://uat-sso.sungardas.com/api/v4/pingid/user/authenticate
             //   - Set Content-Type header to application/json
             //   - Send this payload: 
             //     { "email":"user@example.com", "applicationName":"MyApp" }
             //
             //   - Wait for response. It will return a 200, 202, 403 or 501
             //
             //   - If the response code is 202, the user must continue w/ an OTP.
             //     In that case, capture the sessionId attr in the response
             //     and make another POST to /api/v4/pingid/user/onetimepassword
             //     with a JSON payload as follows:
             //     { "email":"user@example.com", "sessionId":"xxx", "oneTimePassword": "yyy" }
             //
             HttpURLConnection conn = null;
             try 
             {
                 String useOTP = request.getParameter("useotp");

                 if(useOTP == null || useOTP.equals("false"))
                 {
                     //
                     // Try regular ONLINE auth first

                     StringBuilder sBuffer = new StringBuilder();
                     sBuffer.append("{")
                            .append(  "\"email\":\"").append(userEmail).append("\",")
                            .append(  "\"applicationName\":\"ChittaBSandboxApp\",")
                            .append(  "\"applicationIconUrl\":\"https://sites.google.com/site/chittab/Cheetah.png\"")
                            .append("}");

                     URL url = new URL("https://uat-sso.sungardas.com/api/v4/pingid/user/authenticate");
                     conn = (HttpURLConnection)url.openConnection();
                     conn.setRequestMethod("POST");
                     conn.addRequestProperty("Content-Type", "application/json");
                     conn.addRequestProperty("Accept", "*/*");

                     conn.setDoOutput(true);
                     OutputStreamWriter outt = new OutputStreamWriter(conn.getOutputStream(), "UTF-8");
                     outt.write(sBuffer.toString());
                     outt.flush();
                     outt.close();

                     if (conn.getResponseCode() == 200) 
                     {
                        JSONParser jsonParser = new JSONParser();
                        JSONObject jsonObj 
                          = (JSONObject)jsonParser.parse(
                                             new InputStreamReader(conn.getInputStream()));

                        writer.write("You have sucessfully authenticated from an <br/>&nbsp;&nbsp;<b>"
                                     + jsonObj.get("deviceType") + " " 
                                     + jsonObj.get("deviceOSVersion") + " device");
                        if(jsonObj.containsKey("gpsLocation"))
                        {
                            JSONObject location = (JSONObject)jsonObj.get("gpsLocation");
                            writer.write(" at GPS coordinate (" 
                                         + location.get("latitude") + ", "
                                         + location.get("longitude") + ")<br/>");
                            writer.write("&nbsp;&nbsp;<i>(I have no freakin' idea where that is BTW)</i></b>");
                        }
                        writer.write("<hr/>");
                        //writer.write(jsonObj.toString());
                        writer.flush();

                     } 
                     else if (conn.getResponseCode() == 202) 
                     {
                        //
                        // ONLINE auth not available. Either the device is offline 
                        // or the user's a/c supports offline auth only. 
                        //
                        // Capture the sessionId attr from JSON response and a
                        // ask the user to provide OTP.
                        //
                        JSONParser jsonParser = new JSONParser();
                        JSONObject jsonObj 
                          = (JSONObject)jsonParser.parse(
                                             new InputStreamReader(conn.getInputStream()));

                        String sessionId = (String)jsonObj.get("sessionId");

                        //writer.write("<b>It seems like you need to authticate with an OTP.</b><br/><br/>");
                        writer.write("<br/>");
                        writer.write("<form action='application.jsp' method='post'>");
                        writer.write(  "<p> <b>You need to authticate with a One-Time Password:</b> ");
                        writer.write(  "<input type=\"hidden\" name=\"useotp\" value=\"true\"/>");
                        writer.write(  "<input type=\"hidden\" name=\"user\" value=\""+userEmail+"\"/>");
                        writer.write(  "<input type=\"hidden\" name=\"sessionId\" value=\""+sessionId+"\"/>");
                        writer.write(  "<input type=\"text\" name=\"otp\" autofocus placeholder=\"Type your OTP here\"/>");
                        writer.write(  "<input type=\"submit\" style=\"background:yellow;cursor:pointer\"/>");
                        writer.write("</form>");
                        writer.write("<br/>");
                        writer.flush();
                        return;
                     } 
                     else 
                     {
                        writer.write("<br/><h1>2nd factor verification failed for "+ userEmail+ "</h1>");
                        writer.flush();
                        return;
                     }
                 }
                 else
                 {
                     //
                     // OK - User has supplied a OTP. Process it now...

                     StringBuilder sBuffer = new StringBuilder();
                     sBuffer.append("{")
                            .append(  "\"email\":\"").append(userEmail).append("\",")
                            .append(  "\"sessionId\":\"").append(request.getParameter("sessionId")).append("\",")
                            .append(  "\"oneTimePassword\":\"").append(request.getParameter("otp")).append("\"")
                            .append("}");

                     URL url = new URL("https://uat-sso.sungardas.com/api/v4/pingid/user/onetimepassword");
                     conn = (HttpURLConnection)url.openConnection();
                     conn.setRequestMethod("POST");
                     conn.addRequestProperty("Content-Type", "application/json");
                     conn.addRequestProperty("Accept", "*/*");

                     conn.setDoOutput(true);
                     OutputStreamWriter outt = new OutputStreamWriter(conn.getOutputStream(), "UTF-8");
                     outt.write(sBuffer.toString());
                     outt.flush();
                     outt.close();

                     if (conn.getResponseCode() == 200) 
                     {
                        writer.write("User has sucessfully authenticated via OTP.");
                        writer.write("<hr/>");
                        writer.flush();
                     }
                     else
                     {
                        writer.write("<br/><h1>2nd factor verification failed for "+ userEmail+ "</h1>");
                        writer.flush();
                        return;
                     }
                 }
              } 
              catch (Exception ex) 
              {
                 writer.write("<br/><h1>Exception validating 2nd factor for "+ userEmail+ "</h1>");
                 writer.flush();
                 return;
              }
              finally
              {
                  if(conn != null) conn.disconnect();
              }

           }

           writer.write("<br/><h1>User "+ userEmail+ " has been fully authenticated.</h1>");
           writer.write("<br/>");
           Map<String, ArrayList> attrs 
             = (Map<String, ArrayList>)session.getAttribute("userprofile");
           for(String attr : attrs.keySet())
           {
                writer.write("<br/>   *** " + attr + ": " + attrs.get(attr));
           }
           writer.flush();
        %>
    </body>
</html>
