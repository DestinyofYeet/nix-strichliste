(window["webpackJsonpstrichliste-web"]=window["webpackJsonpstrichliste-web"]||[]).push([[4],{522:function(e,a,t){"use strict";t.r(a);var r=t(0),n=t.n(r),c=t(2),l=t(521),m=t(1),s=t(3),i=t.n(s),E=t(10),d=t(6),u=t(11),o=t(20),b=t(12),h=l.g;a.default=function(){var e=window.localStorage.getItem("SELECTED_THEME"),a=function(){var e=Object(r.useState)(null),a=Object(u.a)(e,2),t=a[0],n=a[1];return Object(o.d)(Object(d.a)(i.a.mark(function e(){var a,t;return i.a.wrap(function(e){for(;;)switch(e.prev=e.next){case 0:return e.next=2,Object(o.a)("metrics");case 2:a=e.sent,t=Object(E.a)({},a,{days:a.days.map(function(e){return{balance:e.balance/100,charged:e.charged.amount/100,date:e.date,distinctUsers:e.distinctUsers,spent:e.spent.amount/100,transactions:e.transactions}})}),n(t);case 5:case"end":return e.stop()}},e)})),[]),t}(),t="dark"===e?"white":"black",s="dark"===e?"#2E3D4D":"white";return a?n.a.createElement("div",{style:{margin:"0 1rem"}},n.a.createElement(m.C,{margin:"2rem 0",columns:"1fr 1fr 1fr"},n.a.createElement(m.j,{margin:"1rem 1rem 1rem 0"},n.a.createElement("h2",null,n.a.createElement(c.a,{id:"METRICS_BALANCE",defaultMessage:"balance"})),n.a.createElement(m.d,{value:a.balance},n.a.createElement(b.a,{hidePlusSign:!0,value:a.balance}))),n.a.createElement(m.j,{margin:"1rem 1rem 1rem 1rem"},n.a.createElement("h2",null,n.a.createElement(c.a,{id:"METRICS_USER_COUNT",defaultMessage:"users"})),n.a.createElement(c.b,{value:a.userCount})),n.a.createElement(m.j,{margin:"1rem 0 1rem 1rem"},n.a.createElement("h2",null,n.a.createElement(c.a,{id:"METRICS_TRANSACTION_COUNT",defaultMessage:"transactions"})),n.a.createElement(c.b,{value:a.transactionCount}))),n.a.createElement(m.j,null,n.a.createElement("h2",null,n.a.createElement(c.a,{id:"METRICS_BALANCE",defaultMessage:"balance"})),n.a.createElement(m.G,{margin:"1rem -1rem 2rem -1rem"}),n.a.createElement(l.f,{width:"100%",height:400},n.a.createElement(l.d,{data:a.days},n.a.createElement(l.c,{strokeDasharray:"3 3"}),n.a.createElement(l.h,{dataKey:"date"}),n.a.createElement(l.i,null),n.a.createElement(h,{contentStyle:{background:s}}),n.a.createElement(l.e,{type:"monotone",dataKey:"balance",stroke:t,activeDot:{r:8}}),n.a.createElement(l.a,{dataKey:"charged",barSize:20,fill:"#00cc1d"}),n.a.createElement(l.a,{dataKey:"spent",barSize:20,fill:"#f54963"})))),n.a.createElement(m.j,{margin:"1rem 0"},n.a.createElement("h2",null,n.a.createElement(c.a,{id:"METRICS_USERS",defaultMessage:"Users"})),n.a.createElement(m.G,{margin:"1rem -1rem 2rem -1rem"}),n.a.createElement(l.f,{width:"100%",height:400},n.a.createElement(l.b,{data:a.days},n.a.createElement(l.c,{strokeDasharray:"3 3"}),n.a.createElement(l.h,{dataKey:"date"}),n.a.createElement(l.i,null),n.a.createElement(h,{contentStyle:{background:s}}),n.a.createElement(l.a,{dataKey:"distinctUsers",fill:"#00cc1d"}))))):null}}}]);
//# sourceMappingURL=4.1d5d2912.chunk.js.map