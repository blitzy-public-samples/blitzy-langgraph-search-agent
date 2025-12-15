from langchain_openai import ChatOpenAI
from langchain_community.tools.tavily_search import TavilySearchResults
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import MemorySaver
from app.config import settings
import uuid

# Initialize tools
search_tool = TavilySearchResults(
    max_results=5,
    api_key=settings.TAVILY_API_KEY  # NEW ✅
)

# Initialize LLM
llm = ChatOpenAI(
    model="gpt-4o-mini",
    temperature=0,
    api_key=settings.OPENAI_API_KEY
)

# Create agent with memory
memory = MemorySaver()
agent_executor = create_react_agent(
    llm,
    [search_tool],
    checkpointer=memory
)

def run_agent(query: str, session_id: str = None):
    """Run the agent with a query"""
    if not session_id:
        session_id = str(uuid.uuid4())
    
    config = {"configurable": {"thread_id": session_id}}
    
    result = agent_executor.invoke(
        {"messages": [("user", query)]},
        config=config
    )
    
    # Extract the final response
    messages = result["messages"]
    final_message = messages[-1].content
    
    # Extract sources if available
    sources = []
    for message in messages:
        if hasattr(message, 'tool_calls') and message.tool_calls:
            for tool_call in message.tool_calls:
                if 'tavily' in tool_call.get('name', '').lower():
                    sources.append(tool_call)
    
    return {
        "response": final_message,
        "session_id": session_id,
        "sources": sources
    }
